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

## Requisitos

| Componente | Versión |
|---|---|
| Flutter (stable) | 3.47.1 |
| Dart | 3.13.1 (requisito declarado: `^3.12.2`) |
| Gradle Wrapper | 9.1.0 |
| Android Gradle Plugin | 9.0.1 |
| Kotlin Gradle Plugin | 2.3.20 |
| Java para compilar | 17 (`compileSdk`/`targetSdk` 36, `minSdk` 24, NDK 28.2.13676358) |
| Android SDK | 37.0.0 |
| Xcode | 26.6 (Swift 5.0, deployment target iOS 15.0) |
| CocoaPods | 1.17.0 |

## Ejecutar

Arranque limpio recomendado (los archivos generados no están en Git y se
regeneran solos):

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter run
```

Notas:

- Para iOS, abrir `ios/Runner.xcworkspace` después de `flutter pub get` y
  configurar el equipo de firma en Xcode. Las descripciones de permisos de
  cámara y fotos están incluidas en `ios/Runner/Info.plist`; Android declara
  cámara y acceso a imágenes en el manifest.
- Si Flutter detecta un JDK más nuevo (p. ej. JDK 25) y Gradle falla, apunta
  Gradle a un JDK 17 con `org.gradle.java.home` en
  `android/gradle.properties` (hay una línea comentada de ejemplo).

No hay servicios externos ni Docker. La app funciona offline y no incluye archivos de pruebas.
