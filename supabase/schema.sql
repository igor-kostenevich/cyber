create extension if not exists pgcrypto;

create table if not exists public.participants (
  id          uuid primary key default gen_random_uuid(),
  nickname    text not null,
  real_name   text,
  comment     text,
  status      text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at  timestamptz not null default now()
);

create index if not exists participants_status_idx on public.participants (status);
create index if not exists participants_created_at_idx on public.participants (created_at desc);

create table if not exists public.seal_entries (
  id              uuid primary key default gen_random_uuid(),
  participant_id  uuid not null references public.participants(id) on delete cascade,
  entry_date      date not null default current_date,
  seals_count     integer not null default 0 check (seals_count >= 0),
  closed_count    integer not null default 0 check (closed_count >= 0 and closed_count <= seals_count),
  comment         text,
  created_at      timestamptz not null default now()
);

create index if not exists seal_entries_participant_idx on public.seal_entries (participant_id);
create index if not exists seal_entries_entry_date_idx on public.seal_entries (entry_date desc);

create table if not exists public.app_settings (
  id            integer primary key,
  target_seals  integer not null default 578,
  title         text not null default 'Збір Лунтіку на R9',
  clan_name     text not null default 'Cyberpunk',
  logo_url      text
);

insert into public.app_settings (id, target_seals, title, clan_name, logo_url)
values (1, 578, 'Збір Лунтіку на R9', 'Cyberpunk', null)
on conflict (id) do nothing;

grant usage on schema public to anon, authenticated;

grant select, insert on public.participants to anon;
grant select, insert, update, delete on public.participants to authenticated;

grant select on public.seal_entries to anon;
grant select, insert, update, delete on public.seal_entries to authenticated;

grant select on public.app_settings to anon;
grant select, update on public.app_settings to authenticated;

alter table public.participants  enable row level security;
alter table public.seal_entries  enable row level security;
alter table public.app_settings  enable row level security;

drop policy if exists participants_select_anon on public.participants;
create policy participants_select_anon
  on public.participants
  for select
  to anon
  using (status = 'approved');

drop policy if exists participants_select_authenticated on public.participants;
create policy participants_select_authenticated
  on public.participants
  for select
  to authenticated
  using (true);

drop policy if exists participants_insert_anon on public.participants;
create policy participants_insert_anon
  on public.participants
  for insert
  to anon
  with check (status = 'pending');

drop policy if exists participants_insert_authenticated on public.participants;
create policy participants_insert_authenticated
  on public.participants
  for insert
  to authenticated
  with check (true);

drop policy if exists participants_update_authenticated on public.participants;
create policy participants_update_authenticated
  on public.participants
  for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists participants_delete_authenticated on public.participants;
create policy participants_delete_authenticated
  on public.participants
  for delete
  to authenticated
  using (true);

drop policy if exists seal_entries_select_anon on public.seal_entries;
create policy seal_entries_select_anon
  on public.seal_entries
  for select
  to anon
  using (
    exists (
      select 1
      from public.participants p
      where p.id = seal_entries.participant_id
        and p.status = 'approved'
    )
  );

drop policy if exists seal_entries_select_authenticated on public.seal_entries;
create policy seal_entries_select_authenticated
  on public.seal_entries
  for select
  to authenticated
  using (true);

drop policy if exists seal_entries_insert_authenticated on public.seal_entries;
create policy seal_entries_insert_authenticated
  on public.seal_entries
  for insert
  to authenticated
  with check (true);

drop policy if exists seal_entries_update_authenticated on public.seal_entries;
create policy seal_entries_update_authenticated
  on public.seal_entries
  for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists seal_entries_delete_authenticated on public.seal_entries;
create policy seal_entries_delete_authenticated
  on public.seal_entries
  for delete
  to authenticated
  using (true);

drop policy if exists app_settings_select_all on public.app_settings;
create policy app_settings_select_all
  on public.app_settings
  for select
  to anon, authenticated
  using (true);

drop policy if exists app_settings_update_authenticated on public.app_settings;
create policy app_settings_update_authenticated
  on public.app_settings
  for update
  to authenticated
  using (true)
  with check (true);
