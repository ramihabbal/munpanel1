-- HHHSMUN Supabase setup
-- Project: pmpczworpdlhdwykddso
-- Run this entire script in Supabase SQL Editor.
-- Do NOT put a service_role/secret key in the website.

create table if not exists public.conference_state (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.conference_state (id, data)
values ('main', '{}'::jsonb)
on conflict (id) do nothing;

alter table public.conference_state enable row level security;

-- The current browser app uses the Supabase publishable/anon key and its
-- own conference-role login, so the browser needs read/write access to the
-- single shared conference state row.
drop policy if exists "HHHSMUN read conference state" on public.conference_state;
drop policy if exists "HHHSMUN insert conference state" on public.conference_state;
drop policy if exists "HHHSMUN update conference state" on public.conference_state;

create policy "HHHSMUN read conference state"
on public.conference_state
for select
to anon, authenticated
using (id = 'main');

create policy "HHHSMUN insert conference state"
on public.conference_state
for insert
to anon, authenticated
with check (id = 'main');

create policy "HHHSMUN update conference state"
on public.conference_state
for update
to anon, authenticated
using (id = 'main')
with check (id = 'main');

-- Storage bucket used by the website for conference resources and resolution papers.
insert into storage.buckets (id, name, public)
values ('conference-files', 'conference-files', false)
on conflict (id) do update set public = false;

-- The browser app uploads/downloads files using the publishable/anon key.
-- These policies scope access to the conference-files bucket.
drop policy if exists "HHHSMUN storage read" on storage.objects;
drop policy if exists "HHHSMUN storage upload" on storage.objects;
drop policy if exists "HHHSMUN storage update" on storage.objects;
drop policy if exists "HHHSMUN storage delete" on storage.objects;

create policy "HHHSMUN storage read"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'conference-files');

create policy "HHHSMUN storage upload"
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'conference-files');

create policy "HHHSMUN storage update"
on storage.objects
for update
to anon, authenticated
using (bucket_id = 'conference-files')
with check (bucket_id = 'conference-files');

create policy "HHHSMUN storage delete"
on storage.objects
for delete
to anon, authenticated
using (bucket_id = 'conference-files');

-- Optional verification queries:
select id, updated_at from public.conference_state where id = 'main';
select id, name, public from storage.buckets where id = 'conference-files';
