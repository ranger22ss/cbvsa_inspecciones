-- Control público y no sensible de versiones para la distribución interna.
-- La aplicación consulta esta fila antes de iniciar para exigir actualizaciones.

begin;

create table if not exists public.app_releases (
  platform text primary key,
  latest_version text not null,
  minimum_version text not null,
  download_url text not null,
  release_notes text not null default '',
  force_update boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.app_releases enable row level security;

drop policy if exists "app_releases_public_read" on public.app_releases;
create policy "app_releases_public_read"
on public.app_releases
for select
to anon, authenticated
using (true);

grant select on public.app_releases to anon, authenticated;

insert into public.app_releases (
  platform,
  latest_version,
  minimum_version,
  download_url,
  release_notes,
  force_update,
  updated_at
) values (
  'android',
  '2.0.0',
  '2.0.0',
  'https://github.com/ranger22ss/cbvsa_inspecciones/releases/latest/download/cbvsa-inspecciones.apk',
  'Versión institucional 2.0: inspecciones compartidas, mayor seguridad y mejor rendimiento.',
  true,
  now()
)
on conflict (platform) do update set
  latest_version = excluded.latest_version,
  minimum_version = excluded.minimum_version,
  download_url = excluded.download_url,
  release_notes = excluded.release_notes,
  force_update = excluded.force_update,
  updated_at = excluded.updated_at;

commit;
