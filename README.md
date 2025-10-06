# 🚒 CBVSA Inspecciones

Aplicación móvil desarrollada en **Flutter** para el  
**Cuerpo de Bomberos Voluntarios de San Alberto, Cesar**.  
Permite realizar inspecciones, evaluaciones dinámicas y generar informes PDF con fotografías.

---

## 📌 Tecnologías
- **Flutter** (3.x)
- **Dart**
- **Supabase** (PostgreSQL, Auth, Storage)
- **Riverpod** para estado
- **GoRouter** para navegación

---

## 📌 Flujo del app
1. **Login** con Supabase (usuarios vinculados a tabla `profiles`).  
2. **Hoja 1** – Datos base de la inspección (nombre comercial, representante legal, dirección, celular, foto de fachada, acompañante, inspector).  
3. **Hoja 2** – Selección de tipo de inspección (comercio pequeño, comercio grande, estación de servicio, industria).  
4. **Hoja 3** – Evaluación dinámica con módulos y preguntas. Cada pregunta puede llevar fotos y observaciones.  
5. **Hoja 4** – Resumen y Conclusión: aprobado/no aprobado según puntajes.  
6. **Hoja final** – Registro fotográfico en PDF.  

---

## 📌 Modelo de datos principal (`inspections`)
```json
{
  "id": "uuid",
  "radicado": "string",
  "fecha_inspeccion": "date",
  "nombre_comercial": "string",
  "representante_legal": "string",
  "direccion_rut": "string",
  "celular_rut": "string",
  "acompanante": "string",
  "inspector": {
    "uid": "auth_uid",
    "nombre": "string",
    "rango": "string"
  },
  "foto_fachada_url": "string",
  "visita_anterior": {
    "subsanadas_obs_previas": "bool",
    "emergencias_ultimo_anio": "bool"
  },
  "tipo_inspeccion": "comercio_pequeno|comercio_grande|estacion_servicio|industria",
  "modules": [
    {
      "titulo": "Módulo",
      "items": [
        {
          "pregunta_id": "string",
          "pregunta_texto": "string",
          "respuesta": "string",
          "puntaje": "int",
          "fotos": [
            {
              "url": "string",
              "observacion": "string"
            }
          ]
        }
      ]
    }
  ],
  "resultado": {
    "puntaje_total": "int",
    "aprobado": "bool"
  },
  "created_at": "timestamp"
}

---

## 🛠️ Personalización de nombre, logo e información institucional

| Elemento | Dónde editar |
| --- | --- |
| **Textos visibles en la app** (nombre corto/largo de la estación, lema, datos de contacto, texto del botón “Acerca de…”, nombre por defecto del inspector) | `lib/core/branding/app_branding.dart` |
| **Logo en pantalla “Acerca de”** | Cambia `logoAssetPath` en `lib/core/branding/app_branding.dart`, agrega el archivo en `assets/images/` y decláralo en `pubspec.yaml` dentro de `flutter/assets`. Si no hay logo, se mostrará la sigla. |
| **Nombre de la app en Android** | `android/app/src/main/res/values/strings.xml` (`app_name`). |
| **Nombre de la app en iOS** | `ios/Runner/Info.plist` (`CFBundleDisplayName`). |
| **Descripción del proyecto** | `pubspec.yaml` (`description`). |
| **Iconos de la app** | Reemplaza los archivos en `android/app/src/main/res/mipmap-*` y `ios/Runner/Assets.xcassets/AppIcon.appiconset/`. |
| **Iconos para Web/PWA** | `web/icons/` y el favicon en `web/`.

> 💡 Después de cambiar logos o íconos recuerda correr `flutter pub get` si editas `pubspec.yaml`, y volver a generar íconos con herramientas como [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) si deseas automatizar el proceso.
