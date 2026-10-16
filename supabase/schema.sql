create extension if not exists pgcrypto;
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 160),
  codes jsonb not null default '{}'::jsonb,
  active text not null default 'c' check (active in ('c','python','java')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists projects_user_updated_idx on public.projects(user_id, updated_at desc);
alter table public.projects enable row level security;
drop policy if exists "Users read own projects" on public.projects;
create policy "Users read own projects" on public.projects for select using (auth.uid() = user_id);
drop policy if exists "Users insert own projects" on public.projects;
create policy "Users insert own projects" on public.projects for insert with check (auth.uid() = user_id);
drop policy if exists "Users update own projects" on public.projects;
create policy "Users update own projects" on public.projects for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Users delete own projects" on public.projects;
create policy "Users delete own projects" on public.projects for delete using (auth.uid() = user_id);
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists projects_set_updated_at on public.projects;
create trigger projects_set_updated_at before update on public.projects for each row execute function public.set_updated_at();
grant select, insert, update, delete on public.projects to authenticated;