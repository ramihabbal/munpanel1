-- HHHSMUN Supabase setup
-- Run this entire script once in Supabase SQL Editor.

create table if not exists public.conference_state (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.conference_state enable row level security;

drop policy if exists "conference_state_select" on public.conference_state;
drop policy if exists "conference_state_insert" on public.conference_state;
drop policy if exists "conference_state_update" on public.conference_state;
drop policy if exists "conference_state_delete" on public.conference_state;

create policy "conference_state_select" on public.conference_state for select to anon, authenticated using (true);
create policy "conference_state_insert" on public.conference_state for insert to anon, authenticated with check (true);
create policy "conference_state_update" on public.conference_state for update to anon, authenticated using (true) with check (true);
create policy "conference_state_delete" on public.conference_state for delete to anon, authenticated using (true);

insert into public.conference_state (id, data) values ('main', '{}'::jsonb) on conflict (id) do nothing;

insert into storage.buckets (id, name, public) values ('conference-files', 'conference-files', false) on conflict (id) do nothing;

drop policy if exists "conference_files_select" on storage.objects;
drop policy if exists "conference_files_insert" on storage.objects;
drop policy if exists "conference_files_update" on storage.objects;
drop policy if exists "conference_files_delete" on storage.objects;

create policy "conference_files_select" on storage.objects for select to anon, authenticated using (bucket_id = 'conference-files');
create policy "conference_files_insert" on storage.objects for insert to anon, authenticated with check (bucket_id = 'conference-files');
create policy "conference_files_update" on storage.objects for update to anon, authenticated using (bucket_id = 'conference-files') with check (bucket_id = 'conference-files');
create policy "conference_files_delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'conference-files');
