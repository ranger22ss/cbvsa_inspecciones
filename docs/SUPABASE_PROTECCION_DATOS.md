# Protección de datos y activación de informes compartidos

## 1. Respaldo obligatorio antes de cambiar permisos

Crear una carpeta fuera del proyecto y guardar allí dos respaldos independientes:

1. Base de datos: ejecutar `supabase db dump --linked -f cbvsa_database.sql` o usar `pg_dump` con la cadena de conexión del panel.
2. Fotografías: ejecutar `supabase storage cp -r ss://inspections ./cbvsa_storage --experimental`.

Comprobar que `cbvsa_database.sql` tenga contenido y que la carpeta `cbvsa_storage` incluya fotografías antes de continuar. Los respaldos de Postgres no contienen los objetos de Storage.

## 2. Plan recomendado

Esta aplicación ya almacena información operativa y fotografías. Se recomienda Supabase Pro con límite de gasto activo:

- evita la pausa automática por baja actividad;
- conserva copias diarias de la base durante 7 días;
- amplía la base a 8 GB y Storage a 100 GB;
- no requiere contratar PITR inicialmente.

El plan gratuito puede mantenerse solo si se aceptan pausas, copias manuales frecuentes y límites de 500 MB de base y 1 GB de archivos. Un ping programado puede generar actividad, pero no sustituye copias de seguridad ni convierte el plan gratuito en apropiado para producción.

## 3. Activación de colaboración

1. Ejecutar `supabase/migrations/20260818_team_inspections.sql` en SQL Editor.
2. Confirmar que las tablas `inspections` e `inspection_audit` tienen RLS activo.
3. Entrar con dos cuentas de prueba.
4. Crear un informe con la cuenta A.
5. Abrirlo y editarlo con la cuenta B.
6. Confirmar que el autor original sigue siendo A y que `last_editor` corresponde a B.
7. Confirmar que `inspection_audit` registra el cambio.
8. Publicar la versión de la aplicación que consulta las inspecciones del equipo.

## 4. Política de copias sugerida

- Supabase Pro: respaldo diario administrado por Supabase.
- Exportación lógica externa: semanal.
- Copia de Storage: semanal y antes de cada actualización importante.
- Prueba de restauración: trimestral.
- Conservar al menos una copia fuera de Supabase.

