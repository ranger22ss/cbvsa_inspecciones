import 'package:flutter/material.dart';

/// Centraliza textos y valores relacionados con la imagen institucional
/// para que sea sencillo personalizar la app sin tener que buscar en
/// múltiples archivos.
class AppBranding {
  const AppBranding._();

  /// Nombre corto de la institución (se usa como sigla y logo por defecto).
  static const organizationShortName = 'CBVSA';

  /// Nombre completo que aparece en pantallas informativas.
  static const organizationName =
      'Cuerpo de Bomberos Voluntarios San Alberto, Cesar';

  /// Descripción corta de la aplicación.
  static const appTagline =
      'Aplicación oficial para la gestión de inspecciones en campo.';

  /// Nombre que debería mostrarse en la interfaz de usuario.
  static const appName = 'CBVSA Inspecciones';

  /// Texto por defecto para el inspector que inicia sesión.
  static const inspectorDefaultName = 'Inspector CBVSA';

  /// Texto del botón que lleva a la pantalla "Acerca de".
  static const aboutMenuLabel = 'Acerca de CBVSA';

  /// Datos de contacto que se muestran en la pantalla "Acerca de".
  static const contactLocation = 'San Alberto, Cesar – Colombia';
  static const contactEmail = 'cuerpobomberossanalberto@gmail.com';
  static const contactPhone = '+57 315 353 8706';

  /// Ruta del logo de la institución (opcional).
  ///
  /// Si agregas un archivo en `assets/images/app_logo.png` y lo declaras en
  /// `pubspec.yaml`, la pantalla "Acerca de" lo usará automáticamente.
  static const String? logoAssetPath = null;

  /// Construye el widget del logo que se usa en la pantalla "Acerca de".
  static Widget buildAboutLogo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (logoAssetPath != "../assets/images/app_logo.png") {
      return CircleAvatar(
        radius: 48,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: AssetImage("../assets/images/app_logo.png"),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        organizationShortName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
