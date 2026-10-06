# Appsline CamScanner

MVP de una aplicación Flutter para escanear documentos en Android y iOS.

## Incluye

- Captura de páginas con la cámara trasera.
- Importación de una o varias imágenes desde la galería.
- Ajustes de calidad sin conexión: automático, escala de grises y blanco y negro.
- Documentos multipágina con reordenamiento por arrastre.
- Renombrar y eliminar documentos o páginas.
- Generación de PDF A4 y compartirlo con el diálogo nativo del dispositivo.
- Persistencia local: las imágenes y el índice viven en el directorio privado de la aplicación.

## Ejecutar

Se necesita Flutter 3.22 o superior, Android Studio/Xcode y los SDK correspondientes.

```bash
flutter pub get
flutter run
```

Para iOS, abrir `ios/Runner.xcworkspace` después de `flutter pub get` y configurar el equipo de firma en Xcode. Las descripciones de permisos de cámara y fotos están incluidas en `ios/Runner/Info.plist`; Android declara cámara y acceso a imágenes en el manifest.

No hay servicios externos ni Docker. La app funciona offline y no incluye archivos de pruebas.
