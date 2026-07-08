-- Дробові бали за івенти (до одного десяткового) + налаштування типів активностей

-- ----------------------------------------------------------------------------
--  Таблиця налаштувань балів за типом івенту
-- ----------------------------------------------------------------------------

create table if not exists public.activity_type_settings (
  type       text primary key
               check (type in ('server_boss', 'gvg', 'rb_boss', 'craft')),
  points     numeric(10, 1) not null check (points >= 0),
  updated_at timestamptz not null default now()
);

insert into public.activity_type_settings (type, points) values
  ('gvg',         3),
  ('rb_boss',     2),
  ('server_boss', 3),
  ('craft',       1)
on conflict (type) do nothing;

alter table public.activity_type_settings enable row level security;

grant select, insert, update on public.activity_type_settings to authenticated;

drop policy if exists activity_type_settings_select on public.activity_type_settings;
create policy activity_type_settings_select
  on public.activity_type_settings
  for select
  to authenticated
  using (true);

-- ----------------------------------------------------------------------------
--  Числові колонки: integer → numeric(10,1)
-- ----------------------------------------------------------------------------

alter table public.profiles
  alter column points_balance type numeric(10, 1)
  using points_balance::numeric(10, 1);

alter table public.activities
  alter column points type numeric(10, 1)
  using points::numeric(10, 1);

alter table public.activity_participants
  alter column points_awarded type numeric(10, 1)
  using points_awarded::numeric(10, 1);

alter table public.history
  alter column points type numeric(10, 1)
  using points::numeric(10, 1);

-- ----------------------------------------------------------------------------
--  RPC: оновити стандартні бали за типом (admin)
-- ----------------------------------------------------------------------------

create or replace function public.update_activity_type_points(
  p_type   text,
  p_points numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_points numeric(10, 1);
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if p_type not in ('server_boss', 'gvg', 'rb_boss', 'craft') then
    raise exception 'Невідомий тип активності: %', p_type;
  end if;

  v_points := round(p_points::numeric, 1);

  if v_points < 0 then
    raise exception 'Бали не можуть бути від''ємними';
  end if;

  insert into public.activity_type_settings (type, points, updated_at)
  values (p_type, v_points, now())
  on conflict (type) do update
    set points = excluded.points,
        updated_at = now();
end;
$$;

-- Дозволи на RPC (без цього Supabase блокує виклик)
grant execute on function public.update_activity_type_points(text, numeric) to authenticated;

drop function if exists public.award_activity_points(text, date, text, uuid[]);

drop policy if exists activity_type_settings_insert on public.activity_type_settings;
create policy activity_type_settings_insert
  on public.activity_type_settings
  for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists activity_type_settings_update on public.activity_type_settings;
create policy activity_type_settings_update
  on public.activity_type_settings
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ----------------------------------------------------------------------------
--  RPC: нарахування балів (з опційним p_points)
-- ----------------------------------------------------------------------------

create or replace function public.award_activity_points(
  p_type        text,
  p_date        date,
  p_description text,
  p_profile_ids uuid[],
  p_points      numeric default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_points      numeric(10, 1);
  v_activity_id uuid;
  v_pid         uuid;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if p_type not in ('server_boss', 'gvg', 'rb_boss', 'craft') then
    raise exception 'Невідомий тип активності: %', p_type;
  end if;

  if p_points is not null then
    v_points := round(p_points::numeric, 1);
    if v_points < 0 then
      raise exception 'Бали не можуть бути від''ємними';
    end if;
  else
    select s.points into v_points
    from public.activity_type_settings s
    where s.type = p_type;

    if v_points is null then
      raise exception 'Невідомий тип активності: %', p_type;
    end if;
  end if;

  insert into public.activities (type, points, description, activity_date, created_by)
  values (
    p_type,
    v_points,
    nullif(trim(p_description), ''),
    coalesce(p_date, current_date),
    auth.uid()
  )
  returning id into v_activity_id;

  if p_profile_ids is not null then
    foreach v_pid in array p_profile_ids
    loop
      insert into public.activity_participants (activity_id, profile_id, points_awarded)
      values (v_activity_id, v_pid, v_points)
      on conflict (activity_id, profile_id) do nothing;

      update public.profiles
        set points_balance = points_balance + v_points
        where id = v_pid;

      insert into public.history (type, actor_id, profile_id, activity_id, points, description)
      values ('points_award', auth.uid(), v_pid, v_activity_id, v_points, p_type);
    end loop;
  end if;

  return v_activity_id;
end;
$$;

grant execute on function public.award_activity_points(text, date, text, uuid[], numeric) to authenticated;
