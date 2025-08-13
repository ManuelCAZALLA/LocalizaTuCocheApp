#!/bin/bash

# Script para arreglar dSYMs de Firebase
# Este script debe ejecutarse después del build

echo "🔧 Arreglando dSYMs de Firebase..."

# Directorio donde se encuentran los dSYMs
DSYM_DIR="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Resources/DWARF"

# Verificar si el directorio existe
if [ ! -d "$DSYM_DIR" ]; then
    echo "❌ Directorio de dSYMs no encontrado: $DSYM_DIR"
    exit 1
fi

# Crear dSYMs simbólicos para Firebase si no existen
FIREBASE_FRAMEWORKS=(
    "FirebaseAnalytics"
    "GoogleAdsOnDeviceConversion"
    "GoogleAppMeasurement"
    "GoogleAppMeasurementIdentitySupport"
)

for framework in "${FIREBASE_FRAMEWORKS[@]}"; do
    if [ ! -f "$DSYM_DIR/$framework" ]; then
        echo "📝 Creando dSYM simbólico para $framework"
        ln -sf "${TARGET_NAME}" "$DSYM_DIR/$framework"
    fi
done

echo "✅ dSYMs de Firebase arreglados"


