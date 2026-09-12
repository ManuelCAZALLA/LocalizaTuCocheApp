#!/bin/bash

# Script para copiar dSYMs de Firebase desde SPM al archivo
# Este script debe ejecutarse como un Build Phase "Run Script" después de "Copy Bundle Resources"
# Durante el archiving, se ejecuta automáticamente

# No usar set -e para evitar fallos del build si algo no se encuentra
set -uo pipefail

echo "🔧 Copiando dSYMs de Firebase..."

# Directorio donde se encuentran los dSYMs del app
APP_DSYM_DIR="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF"

# Verificar si estamos en modo archiving
if [ "${CONFIGURATION}" != "Release" ] && [ "${ACTION}" != "install" ]; then
    # Durante builds regulares, solo verificar que el directorio existe
    if [ ! -d "$APP_DSYM_DIR" ]; then
        echo "ℹ️ Modo build regular - dSYMs se generarán durante archiving"
        exit 0
    fi
fi

# Verificar si el directorio existe
if [ ! -d "$APP_DSYM_DIR" ]; then
    echo "⚠️ Directorio de dSYMs no encontrado: $APP_DSYM_DIR"
    echo "   Esto puede ser normal durante algunos builds."
    exit 0
fi

# Lista de frameworks de Firebase que necesitan dSYM (sin Google Ads)
FRAMEWORKS=(
    "FirebaseAnalytics"
    "GoogleAppMeasurement"
    "GoogleAppMeasurementIdentitySupport"
)

# Función para buscar dSYM de un framework en múltiples ubicaciones
find_framework_dsym() {
    local framework_name=$1
    
    # Ubicaciones donde SPM puede almacenar los frameworks
    local possible_paths=(
        # Xcode 15+ ubicación estándar
        "${BUILD_ROOT%/Build/Products*}/SourcePackages/checkouts"
        "${BUILD_ROOT%/Build/Products*}/SourcePackages/build"
        # Xcode 14 y anteriores
        "${BUILD_DIR%/Build/*}/SourcePackages/checkouts"
        "${BUILD_DIR%/Build/*}/SourcePackages/build"
        # DerivedData
        "${HOME}/Library/Developer/Xcode/DerivedData"/*/SourcePackages/checkouts
        "${HOME}/Library/Developer/Xcode/DerivedData"/*/SourcePackages/build
        # Build directory
        "${BUILD_DIR}"
        "${BUILD_ROOT}"
    )
    
    # Buscar el dSYM del framework
    for base_path in "${possible_paths[@]}"; do
        if [ ! -d "$base_path" ]; then
            continue
        fi
        
        # Buscar el dSYM directamente
        local dsym=$(find "$base_path" -name "${framework_name}.framework.dSYM" -type d 2>/dev/null | head -1)
        
        if [ -n "$dsym" ]; then
            local dwarf_file="${dsym}/Contents/Resources/DWARF/${framework_name}"
            if [ -f "$dwarf_file" ]; then
                echo "$dwarf_file"
                return 0
            fi
        fi
        
        # También buscar en productos de build
        local built_dsym=$(find "$base_path" -path "*/${framework_name}.framework.dSYM/Contents/Resources/DWARF/${framework_name}" -type f 2>/dev/null | head -1)
        if [ -n "$built_dsym" ]; then
            echo "$built_dsym"
            return 0
        fi
    done
    
    return 1
}

# Función para copiar dSYM verificando UUID
copy_dsym() {
    local source_dsym=$1
    local framework_name=$2
    local dest_path="${APP_DSYM_DIR}/${framework_name}"
    
    if [ -z "$source_dsym" ] || [ ! -f "$source_dsym" ]; then
        return 1
    fi
    
    # Obtener UUID del dSYM fuente
    local source_uuid=$(dwarfdump -u "$source_dsym" 2>/dev/null | grep -o '[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}' | head -1 || echo "")
    
    if [ -z "$source_uuid" ]; then
        echo "   ⚠️ No se pudo obtener UUID de $source_dsym"
        # Intentar copiar de todas formas
    fi
    
    # Copiar el archivo
    cp -f "$source_dsym" "$dest_path" 2>/dev/null || {
        echo "   ❌ Error al copiar ${framework_name}"
        return 1
    }
    
    # Verificar que se copió correctamente
    if [ -f "$dest_path" ]; then
        local dest_uuid=$(dwarfdump -u "$dest_path" 2>/dev/null | grep -o '[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}' | head -1 || echo "")
        
        if [ -n "$source_uuid" ] && [ -n "$dest_uuid" ] && [ "$source_uuid" = "$dest_uuid" ]; then
            echo "   ✅ Copiado ${framework_name} (UUID: ${source_uuid})"
        elif [ -n "$source_uuid" ]; then
            echo "   ✅ Copiado ${framework_name} (UUID fuente: ${source_uuid}, destino: ${dest_uuid})"
        else
            echo "   ✅ Copiado ${framework_name}"
        fi
        return 0
    else
        echo "   ❌ Error: archivo no se copió correctamente"
        return 1
    fi
}

# Procesar cada framework
copied_count=0
failed_count=0
skipped_count=0

echo ""
for framework in "${FRAMEWORKS[@]}"; do
    # Verificar si ya existe
    if [ -f "${APP_DSYM_DIR}/${framework}" ]; then
        local existing_uuid=$(dwarfdump -u "${APP_DSYM_DIR}/${framework}" 2>/dev/null | grep -o '[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}' | head -1 || echo "")
        if [ -n "$existing_uuid" ]; then
            echo "   ✅ ${framework} ya existe (UUID: ${existing_uuid})"
        else
            echo "   ✅ ${framework} ya existe"
        fi
        ((skipped_count++))
        continue
    fi
    
    echo -n "   🔍 Buscando dSYM para ${framework}... "
    dsym_path=$(find_framework_dsym "$framework" 2>/dev/null || echo "")
    
    if [ -n "$dsym_path" ]; then
        echo "encontrado"
        if copy_dsym "$dsym_path" "$framework"; then
            ((copied_count++))
        else
            ((failed_count++))
        fi
    else
        echo "no encontrado"
        ((failed_count++))
    fi
done

echo ""
echo "📊 Resumen:"
echo "   ✅ Copiados: ${copied_count}"
echo "   ⏭️  Ya existían: ${skipped_count}"
echo "   ⚠️  No encontrados/Fallidos: ${failed_count}"

# No fallar el build si algunos dSYM no se encuentran
# Los dSYMs pueden generarse durante el proceso de archiving
exit 0
