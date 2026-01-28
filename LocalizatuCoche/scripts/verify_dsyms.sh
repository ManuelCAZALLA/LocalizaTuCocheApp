#!/bin/bash

# Script para verificar que los dSYM están presentes después de archivar
# Ejecutar manualmente después de crear un archivo para verificar

ARCHIVE_PATH="${1:-}"

if [ -z "$ARCHIVE_PATH" ]; then
    echo "Uso: ./verify_dsyms.sh <ruta_al_archivo.xcarchive>"
    echo ""
    echo "Ejemplo:"
    echo "  ./verify_dsyms.sh ~/Library/Developer/Xcode/Archives/2024-01-15/YourApp.xcarchive"
    exit 1
fi

DSYM_DIR="${ARCHIVE_PATH}/dSYMs"

if [ ! -d "$DSYM_DIR" ]; then
    echo "❌ No se encontró el directorio dSYMs en: $ARCHIVE_PATH"
    exit 1
fi

echo "🔍 Verificando dSYMs en: $DSYM_DIR"
echo ""

FRAMEWORKS=(
    "FirebaseAnalytics"
    "GoogleAdsOnDeviceConversion"
    "GoogleAppMeasurement"
    "GoogleAppMeasurementIdentitySupport"
    "GoogleMobileAds"
    "UserMessagingPlatform"
)

APP_DSYM=$(find "$DSYM_DIR" -name "*.app.dSYM" -type d | head -1)

if [ -z "$APP_DSYM" ]; then
    echo "⚠️ No se encontró el dSYM principal de la app"
else
    echo "✅ dSYM principal encontrado: $(basename "$APP_DSYM")"
    APP_DWARF="${APP_DSYM}/Contents/Resources/DWARF"
    
    if [ -d "$APP_DWARF" ]; then
        echo ""
        echo "📋 Contenido del directorio DWARF:"
        ls -lh "$APP_DWARF" | tail -n +2
        echo ""
    fi
fi

echo "🔍 Verificando frameworks:"
echo ""

all_found=true
for framework in "${FRAMEWORKS[@]}"; do
    # Buscar en el dSYM de la app
    if [ -d "$APP_DWARF" ] && [ -f "${APP_DWARF}/${framework}" ]; then
        uuid=$(dwarfdump -u "${APP_DWARF}/${framework}" 2>/dev/null | grep -o '[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}' | head -1 || echo "")
        if [ -n "$uuid" ]; then
            echo "  ✅ ${framework} (UUID: ${uuid})"
        else
            echo "  ⚠️  ${framework} (presente pero UUID no disponible)"
        fi
    else
        echo "  ❌ ${framework} (NO ENCONTRADO)"
        all_found=false
    fi
done

echo ""
if [ "$all_found" = true ]; then
    echo "✅ Todos los dSYM están presentes"
    exit 0
else
    echo "❌ Faltan algunos dSYM. Revisa la configuración del script de build phase."
    exit 1
fi
