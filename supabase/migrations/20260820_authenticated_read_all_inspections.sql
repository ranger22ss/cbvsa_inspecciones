-- Todos los usuarios autenticados pueden consultar y descargar inspecciones.
-- Solo el autor conserva permisos de creación y actualización sobre sus registros.
-- Se eliminan políticas públicas que permitían operaciones sin autenticación.

begin;

alter table public.inspections enable row level security;

drop policy if exists "libre_all" on public.inspections;
drop policy if exists "Libre para todos - SELECT" on public.inspections;
drop policy if exists "Libre para todos - INSERT" on public.inspections;
drop policy if exists "Libre para todos - UPDATE" on public.inspections;
drop policy if exists "Libre para todos - DELETE" on public.inspections;
drop policy if exists "authenticated_users_can_view_all_inspections"
  on public.inspections;

create policy "authenticated_users_can_view_all_inspections"
on public.inspections
for select
to authenticated
using (true);

commit;
