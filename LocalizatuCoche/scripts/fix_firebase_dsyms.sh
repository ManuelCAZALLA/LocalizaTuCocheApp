#!/bin/bash

# Script para arreglar dSYMs de Firebase
# Este script debe ejecutarse después del build

echo "🔧 Arreglando dSYMs de Firebase..."

# Directorio donde se encuentran los dSYMs
DSYM_DIR="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Resources/DWARF"

# Verificar si el directorio existe
if [ ! -d "$DSYM_DIR" ]; then
    echo "❌ Directorio de dSYMs no encontrado: $DSYM_DIR"
    exit 0  # No fallar el build si no encuentra el directorio
fi

# Crear dSYMs simbólicos para Firebase si no existen
FIREBASE_FRAMEWORKS=(
    "FirebaseAnalytics"
    "GoogleAdsOnDeviceConversion"
    "GoogleAppMeasurement"
    "GoogleAppMeasurementIdentitySupport"
)

# Buscar el archivo principal del ejecutable
MAIN_EXECUTABLE=""
if [ -f "$DSYM_DIR/${TARGET_NAME}" ]; then
    MAIN_EXECUTABLE="${TARGET_NAME}"
elif [ -f "$DSYM_DIR/${PRODUCT_NAME}" ]; then
    MAIN_EXECUTABLE="${PRODUCT_NAME}"
else
    # Buscar cualquier archivo ejecutable
    MAIN_EXECUTABLE=$(ls "$DSYM_DIR" | head -1)
fi

if [ -z "$MAIN_EXECUTABLE" ]; then
    echo "⚠️ No se encontró archivo ejecutable principal en $DSYM_DIR"
    echo "📋 Contenido del directorio:"
    ls -la "$DSYM_DIR" || true
    exit 0  # No fallar el build
fi

echo "📝 Usando $MAIN_EXECUTABLE como base para dSYMs"

for framework in "${FIREBASE_FRAMEWORKS[@]}"; do
    if [ ! -f "$DSYM_DIR/$framework" ]; then
        echo "📝 Creando dSYM simbólico para $framework"
        ln -sf "$MAIN_EXECUTABLE" "$DSYM_DIR/$framework"
    else
        echo "✅ dSYM para $framework ya existe"
    fi
done

echo "✅ dSYMs de Firebase procesados"
