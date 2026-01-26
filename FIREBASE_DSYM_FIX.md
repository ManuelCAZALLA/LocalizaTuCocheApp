# Solución para dSYM faltantes de Firebase y Google Ads

Este documento explica cómo resolver el problema de dSYM faltantes para los frameworks de Firebase y Google Ads cuando se usa Swift Package Manager.

## Problema

Al archivar la aplicación, Xcode muestra errores indicando que faltan dSYM para los siguientes frameworks:
- FirebaseAnalytics
- GoogleAdsOnDeviceConversion
- GoogleAppMeasurement
- GoogleAppMeasurementIdentitySupport
- GoogleMobileAds
- UserMessagingPlatform

## Solución

Se ha creado un script (`copy_firebase_dsyms.sh`) que busca y copia automáticamente los dSYM de estos frameworks desde los directorios de Swift Package Manager al archivo durante el proceso de archiving.

## Pasos para configurar

### 1. Agregar el script como Build Phase

1. Abre el proyecto en Xcode
2. Selecciona el target **LocalizatuCoche** en el navegador del proyecto
3. Ve a la pestaña **Build Phases**
4. Haz clic en el botón **+** en la parte superior izquierda
5. Selecciona **New Run Script Phase**
6. Arrastra el nuevo script phase para que esté **después** de "Copy Bundle Resources" pero **antes** de cualquier script de Firebase Crashlytics
7. Expande el script phase y configura lo siguiente:
   - **Name**: `Copy Firebase dSYMs`
   - **Shell**: `/bin/sh`
   - **Script**: Agrega el siguiente contenido:

```bash
"${SRCROOT}/LocalizatuCoche/scripts/copy_firebase_dsyms.sh"
```

8. En **Input Files**, agrega:
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF`

9. En **Output Files**, agrega (opcional, para mejor rendimiento):
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/FirebaseAnalytics`
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/GoogleAdsOnDeviceConversion`
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/GoogleAppMeasurement`
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/GoogleAppMeasurementIdentitySupport`
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/GoogleMobileAds`
   - `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/UserMessagingPlatform`

10. **IMPORTANTE**: Desmarca la opción **"For install builds only"** para que el script se ejecute también durante el archiving

### 2. Verificar configuración de Debug Information Format

Asegúrate de que en **Build Settings** > **Debug Information Format** esté configurado como:
- **Debug**: `DWARF` (opcional, para builds más rápidos)
- **Release**: `DWARF with dSYM File` (obligatorio)

### 3. Verificar script de Firebase Crashlytics

Si tienes un script de Firebase Crashlytics configurado, asegúrate de que esté **después** del script de copia de dSYM y que tenga los siguientes Input Files:

```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist
$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
```

## Cómo funciona

El script `copy_firebase_dsyms.sh`:

1. Busca los dSYM de los frameworks de Firebase/Google Ads en múltiples ubicaciones donde Swift Package Manager puede almacenarlos
2. Verifica los UUID de los dSYM encontrados
3. Copia los dSYM al directorio del archivo de la aplicación
4. Verifica que la copia fue exitosa comparando UUIDs

## Verificación

Después de configurar el script:

1. Archiva la aplicación (Product > Archive)
2. Durante el archiving, revisa los logs del build para ver mensajes como:
   - `✅ Copiado FirebaseAnalytics (UUID: ...)`
   - `✅ Copiado GoogleMobileAds (UUID: ...)`
3. Después de archivar, verifica que los dSYM estén presentes:
   - Abre el archivo en Organizer
   - Haz clic derecho en el archivo > "Show in Finder"
   - Navega a `YourApp.xcarchive/dSYMs/`
   - Verifica que existan los dSYM de los frameworks

## Solución alternativa (si el script no funciona)

Si el script no encuentra los dSYM, puede ser que los frameworks estén en una ubicación diferente. En ese caso:

1. Busca manualmente los dSYM de los frameworks en:
   ```
   ~/Library/Developer/Xcode/DerivedData/[TuProyecto]-[Hash]/SourcePackages/checkouts/
   ```

2. Copia manualmente los `.framework.dSYM` al archivo después de archivarlo

3. O usa el script de Firebase Crashlytics que debería manejar esto automáticamente si está correctamente configurado

## Notas

- Este es un problema conocido con Firebase y Google frameworks cuando se usa Swift Package Manager
- El script está diseñado para no fallar el build si no encuentra algunos dSYM (puede ser normal en algunos casos)
- Los dSYM pueden generarse durante el proceso de archiving, por lo que el script verifica múltiples ubicaciones

