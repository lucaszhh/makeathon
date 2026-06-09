-- Quadrant App — Supabase Migration
-- Run this in Supabase SQL Editor to create the full schema

-- 0. Extensions
create extension if not exists "pgcrypto";

-- 1. Users (extends Supabase auth.users)
create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nombre text,
  foto_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Workspaces
create table if not exists public.espacios_de_trabajo (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  nombre text not null default 'Mi espacio',
  slug text,
  es_predeterminado boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(usuario_id, slug)
);

-- 3. Vision & Mission
create table if not exists public.visiones (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  titulo text default 'Mi Visión',
  descripcion text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(espacio_trabajo_id)
);

create table if not exists public.misiones (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  titulo text default 'Mi Misión',
  descripcion text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(espacio_trabajo_id)
);

-- 4. Principles
create table if not exists public.principios (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  titulo text not null,
  descripcion text,
  posicion int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. Domains (Ámbitos)
create table if not exists public.ambitos (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  nombre text not null,
  descripcion text,
  color text default '#1a56db',
  icono text default 'star',
  posicion int not null default 0,
  es_sistema boolean not null default false,
  archivado boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 6. Roles
create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  ambito_id uuid references public.ambitos(id) on delete set null,
  nombre text not null,
  descripcion text,
  posicion int not null default 0,
  es_sistema boolean not null default false,
  archivado boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 7. Objectives
do $$ begin create type objetivo_horizonte as enum ('3_meses', '6_meses', '1_anio', '3_anios'); exception when duplicate_object then null; end; $$;
do $$ begin create type objetivo_estado as enum ('activo', 'completado', 'archivado'); exception when duplicate_object then null; end; $$;

create table if not exists public.objetivos (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  rol_id uuid references public.roles(id) on delete set null,
  titulo text not null,
  descripcion text,
  tipo text default 'personal',
  horizonte objetivo_horizonte default '6_meses',
  estado objetivo_estado not null default 'activo',
  prioridad int not null default 3 check (prioridad between 1 and 5),
  fecha_inicio date default current_date,
  fecha_objetivo date,
  archivado boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 8. Goals (Metas) — the core entity with prioritization fields
do $$ begin create type meta_estado as enum ('pendiente', 'en_progreso', 'completada', 'archivada'); exception when duplicate_object then null; end; $$;
do $$ begin create type producto_estado as enum ('idea', 'validacion', 'construccion', 'lanzado', 'escalando'); exception when duplicate_object then null; end; $$;

create table if not exists public.metas (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  objetivo_id uuid references public.objetivos(id) on delete cascade,
  titulo text not null,
  descripcion text,
  estado meta_estado not null default 'pendiente',
  periodo text,
  progreso int not null default 0 check (progreso between 0 and 100),
  impacto int not null default 3 check (impacto between 1 and 5),
  esfuerzo int not null default 3 check (esfuerzo between 1 and 5),
  urgencia int not null default 3 check (urgencia between 1 and 5),
  importancia int not null default 3 check (importancia between 1 and 5),
  score numeric(5,2) generated always as (
    round((urgencia * importancia * impacto) * (esfuerzo::numeric / 5), 2)
  ) stored,
  tipo_prioridad text default 'automatica',
  estado_producto producto_estado default 'idea',
  fecha_inicio date,
  fecha_objetivo date,
  archivado boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 9. Tasks
do $$ begin create type tarea_estado as enum ('pendiente', 'en_progreso', 'completada'); exception when duplicate_object then null; end; $$;

create table if not exists public.tareas (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  meta_id uuid references public.metas(id) on delete cascade,
  titulo text not null,
  descripcion text,
  estado tarea_estado not null default 'pendiente',
  prioridad text default 'media',
  fecha_vencimiento date,
  completada boolean not null default false,
  completada_at timestamptz,
  posicion int not null default 0,
  archivada boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 10. Weekly Plans
create table if not exists public.planes_semanales (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  semana_inicio date not null,
  enfoque text,
  notas text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(espacio_trabajo_id, semana_inicio)
);

do $$ begin create type tipo_item_semanal as enum ('meta', 'tarea', 'nota'); exception when duplicate_object then null; end; $$;

create table if not exists public.items_plan_semanal (
  id uuid primary key default gen_random_uuid(),
  plan_semanal_id uuid not null references public.planes_semanales(id) on delete cascade,
  rol_id uuid references public.roles(id) on delete set null,
  objetivo_id uuid references public.objetivos(id) on delete set null,
  meta_id uuid references public.metas(id) on delete set null,
  tarea_id uuid references public.tareas(id) on delete set null,
  titulo text not null,
  tipo_item tipo_item_semanal not null default 'meta',
  posicion int not null default 0,
  completado boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 11. Habits
do $$ begin create type habito_frecuencia as enum ('diario', 'semanal', 'mensual'); exception when duplicate_object then null; end; $$;
do $$ begin create type habito_estado as enum ('activo', 'pausado', 'archivado'); exception when duplicate_object then null; end; $$;

create table if not exists public.habitos (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  rol_id uuid references public.roles(id) on delete set null,
  nombre text not null,
  descripcion text,
  frecuencia habito_frecuencia not null default 'diario',
  estado habito_estado not null default 'activo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 12. Notes
do $$ begin create type tipo_nota as enum ('general', 'reflexion', 'idea', 'aprendizaje'); exception when duplicate_object then null; end; $$;

create table if not exists public.notas (
  id uuid primary key default gen_random_uuid(),
  espacio_trabajo_id uuid not null references public.espacios_de_trabajo(id) on delete cascade,
  ambito_id uuid references public.ambitos(id) on delete set null,
  rol_id uuid references public.roles(id) on delete set null,
  titulo text not null,
  contenido text,
  tipo tipo_nota not null default 'general',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes for performance
create index idx_espacios_trabajo_usuario on public.espacios_de_trabajo(usuario_id);
create index idx_ambitos_espacio on public.ambitos(espacio_trabajo_id);
create index idx_roles_espacio on public.roles(espacio_trabajo_id);
create index idx_roles_ambito on public.roles(ambito_id);
create index idx_objetivos_rol on public.objetivos(rol_id);
create index idx_objetivos_estado on public.objetivos(estado);
create index idx_metas_objetivo on public.metas(objetivo_id);
create index idx_metas_score on public.metas(score desc);
create index idx_metas_estado on public.metas(estado);
create index idx_tareas_meta on public.tareas(meta_id);
create index idx_planes_semanales_espacio on public.planes_semanales(espacio_trabajo_id);
create index idx_items_plan_semanal_plan on public.items_plan_semanal(plan_semanal_id);

-- Trigger: auto-update updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_usuarios_updated_at before update on public.usuarios for each row execute function public.set_updated_at();
create trigger trg_espacios_de_trabajo_updated_at before update on public.espacios_de_trabajo for each row execute function public.set_updated_at();
create trigger trg_visiones_updated_at before update on public.visiones for each row execute function public.set_updated_at();
create trigger trg_misiones_updated_at before update on public.misiones for each row execute function public.set_updated_at();
create trigger trg_principios_updated_at before update on public.principios for each row execute function public.set_updated_at();
create trigger trg_ambitos_updated_at before update on public.ambitos for each row execute function public.set_updated_at();
create trigger trg_roles_updated_at before update on public.roles for each row execute function public.set_updated_at();
create trigger trg_objetivos_updated_at before update on public.objetivos for each row execute function public.set_updated_at();
create trigger trg_metas_updated_at before update on public.metas for each row execute function public.set_updated_at();
create trigger trg_tareas_updated_at before update on public.tareas for each row execute function public.set_updated_at();
create trigger trg_planes_semanales_updated_at before update on public.planes_semanales for each row execute function public.set_updated_at();
create trigger trg_items_plan_semanal_updated_at before update on public.items_plan_semanal for each row execute function public.set_updated_at();
create trigger trg_habitos_updated_at before update on public.habitos for each row execute function public.set_updated_at();
create trigger trg_notas_updated_at before update on public.notas for each row execute function public.set_updated_at();

-- Row Level Security
alter table public.usuarios enable row level security;
alter table public.espacios_de_trabajo enable row level security;
alter table public.visiones enable row level security;
alter table public.misiones enable row level security;
alter table public.principios enable row level security;
alter table public.ambitos enable row level security;
alter table public.roles enable row level security;
alter table public.objetivos enable row level security;
alter table public.metas enable row level security;
alter table public.tareas enable row level security;
alter table public.planes_semanales enable row level security;
alter table public.items_plan_semanal enable row level security;
alter table public.habitos enable row level security;
alter table public.notas enable row level security;

-- RLS Policies: users can only access their own data
create policy "Usuarios pueden ver su propio perfil"
  on public.usuarios for select
  using (auth.uid() = id);

create policy "Usuarios pueden insertar su perfil"
  on public.usuarios for insert
  with check (auth.uid() = id);

create policy "Usuarios pueden actualizar su perfil"
  on public.usuarios for update
  using (auth.uid() = id);

-- Helper function: user owns the workspace
create or replace function public.user_owns_workspace(ws_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.espacios_de_trabajo
    where id = ws_id and usuario_id = auth.uid()
  );
end;
$$ language plpgsql security definer;

-- Workspace-scoped RLS
do $$
declare
  tables_with_workspace text[] := array[
    'espacios_de_trabajo', 'visiones', 'misiones', 'principios',
    'ambitos', 'roles', 'objetivos', 'metas', 'tareas',
    'planes_semanales', 'items_plan_semanal', 'habitos', 'notas'
  ];
  t text;
begin
  foreach t in array tables_with_workspace
  loop
    if t = 'espacios_de_trabajo' then
      execute format(
        'create policy "Propietario puede gestionar sus espacios"
         on public.%I for all
         using (usuario_id = auth.uid())
         with check (usuario_id = auth.uid())',
        t
      );
    else
      execute format(
        'create policy "Propietario del workspace puede gestionar"
         on public.%I for all
         using (public.user_owns_workspace(espacio_trabajo_id))
         with check (public.user_owns_workspace(espacio_trabajo_id))',
        t
      );
    end if;
  end loop;
end;
$$;
