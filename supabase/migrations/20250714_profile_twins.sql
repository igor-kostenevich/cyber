-- Твінки (неосновні персонажі) + нарахування з бонусом 20%

-- ----------------------------------------------------------------------------
--  Таблиця твінків
-- ----------------------------------------------------------------------------

create table if not exists public.profile_twins (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  nickname   text not null check (char_length(trim(nickname)) >= 2),
  created_at timestamptz not null default now(),
  unique (profile_id, nickname)
);

create index if not exists profile_twins_profile_idx
  on public.profile_twins (profile_id);

alter table public.profile_twins enable row level security;

grant select, insert, delete on public.profile_twins to authenticated;

drop policy if exists profile_twins_select on public.profile_twins;
create policy profile_twins_select
  on public.profile_twins
  for select
  to authenticated
  using (
    profile_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.profiles p
      where p.id = profile_twins.profile_id
        and p.status = 'approved'
    )
  );

drop policy if exists profile_twins_insert on public.profile_twins;
create policy profile_twins_insert
  on public.profile_twins
  for insert
  to authenticated
  with check (
    profile_id = auth.uid()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.status in ('pending', 'approved')
    )
  );

drop policy if exists profile_twins_delete on public.profile_twins;
create policy profile_twins_delete
  on public.profile_twins
  for delete
  to authenticated
  using (profile_id = auth.uid());

-- ----------------------------------------------------------------------------
--  Бонус твінка для типів івентів
-- ----------------------------------------------------------------------------

alter table public.activity_type_settings
  add column if not exists twin_bonus_enabled boolean not null default false;

update public.activity_type_settings
  set twin_bonus_enabled = true
  where type in ('gvg', 'rb_boss');

-- ----------------------------------------------------------------------------
--  Учасники активності: режим нарахування + твінк
-- ----------------------------------------------------------------------------

alter table public.activity_participants
  add column if not exists twin_id uuid references public.profile_twins (id) on delete set null;

alter table public.activity_participants
  add column if not exists award_mode text not null default 'main'
    check (award_mode in ('main', 'main_with_twin', 'twin_only'));

-- ----------------------------------------------------------------------------
--  RPC: додати / видалити твінка (власник акаунта)
-- ----------------------------------------------------------------------------

create or replace function public.add_profile_twin(p_nickname text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid      uuid := auth.uid();
  v_nickname text := trim(p_nickname);
  v_twin_id  uuid;
begin
  if v_uid is null then
    raise exception 'Потрібна авторизація' using errcode = '42501';
  end if;

  if char_length(v_nickname) < 2 then
    raise exception 'Нік твінка занадто короткий';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = v_uid and status in ('pending', 'approved')
  ) then
    raise exception 'Профіль недоступний' using errcode = '42501';
  end if;

  if lower(v_nickname) = (
    select lower(nickname) from public.profiles where id = v_uid
  ) then
    raise exception 'Твінк не може збігатися з основним ніком';
  end if;

  insert into public.profile_twins (profile_id, nickname)
  values (v_uid, v_nickname)
  on conflict (profile_id, nickname) do nothing
  returning id into v_twin_id;

  if v_twin_id is null then
    select id into v_twin_id
    from public.profile_twins
    where profile_id = v_uid and nickname = v_nickname;
  end if;

  return v_twin_id;
end;
$$;

create or replace function public.remove_profile_twin(p_twin_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Потрібна авторизація' using errcode = '42501';
  end if;

  delete from public.profile_twins
  where id = p_twin_id
    and profile_id = auth.uid();

  if not found then
    raise exception 'Твінк не знайдено' using errcode = 'P0002';
  end if;
end;
$$;

grant execute on function public.add_profile_twin(text) to authenticated;
grant execute on function public.remove_profile_twin(uuid) to authenticated;

-- ----------------------------------------------------------------------------
--  RPC: нарахування балів (з підтримкою твінків)
-- ----------------------------------------------------------------------------

drop function if exists public.award_activity_points(text, date, text, uuid[], numeric);

create or replace function public.award_activity_points(
  p_type        text,
  p_date        date,
  p_description text,
  p_profile_ids uuid[] default null,
  p_points      numeric default null,
  p_awards      jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_base_points   numeric(10, 1);
  v_activity_id   uuid;
  v_twin_bonus    boolean;
  v_award         jsonb;
  v_pid           uuid;
  v_twin_id       uuid;
  v_mode          text;
  v_awarded       numeric(10, 1);
  v_twin_nick     text;
  v_hist_desc     text;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if p_type not in ('server_boss', 'gvg', 'rb_boss', 'craft') then
    raise exception 'Невідомий тип активності: %', p_type;
  end if;

  if p_points is not null then
    v_base_points := round(p_points::numeric, 1);
    if v_base_points < 0 then
      raise exception 'Бали не можуть бути від''ємними';
    end if;
  else
    select s.points into v_base_points
    from public.activity_type_settings s
    where s.type = p_type;

    if v_base_points is null then
      raise exception 'Невідомий тип активності: %', p_type;
    end if;
  end if;

  select coalesce(s.twin_bonus_enabled, false) into v_twin_bonus
  from public.activity_type_settings s
  where s.type = p_type;

  insert into public.activities (type, points, description, activity_date, created_by)
  values (
    p_type,
    v_base_points,
    nullif(trim(p_description), ''),
    coalesce(p_date, current_date),
    auth.uid()
  )
  returning id into v_activity_id;

  if p_awards is not null and jsonb_typeof(p_awards) = 'array' then
    for v_award in select value from jsonb_array_elements(p_awards)
    loop
      v_pid := (v_award->>'profile_id')::uuid;
      v_mode := coalesce(nullif(trim(v_award->>'award_mode'), ''), 'main');
      v_twin_id := nullif(v_award->>'twin_id', '')::uuid;

      if v_pid is null then
        continue;
      end if;

      if v_mode not in ('main', 'main_with_twin', 'twin_only') then
        raise exception 'Невідомий режим нарахування: %', v_mode;
      end if;

      if not exists (
        select 1 from public.profiles
        where id = v_pid and status = 'approved'
      ) then
        raise exception 'Гравець не підтверджений: %', v_pid;
      end if;

      if v_mode in ('main_with_twin', 'twin_only') then
        if v_twin_id is null then
          raise exception 'Оберіть твінка для гравця %', v_pid;
        end if;

        select t.nickname into v_twin_nick
        from public.profile_twins t
        where t.id = v_twin_id and t.profile_id = v_pid;

        if v_twin_nick is null then
          raise exception 'Твінк не належить гравцю';
        end if;
      else
        v_twin_id := null;
        v_twin_nick := null;
      end if;

      if v_mode = 'main_with_twin' and not v_twin_bonus then
        raise exception 'Бонус твінка недоступний для цього типу івенту';
      end if;

      v_awarded := case v_mode
        when 'main' then v_base_points
        when 'main_with_twin' then round(v_base_points * 1.2, 1)
        when 'twin_only' then round(v_base_points * 0.2, 1)
      end;

      insert into public.activity_participants (
        activity_id, profile_id, points_awarded, twin_id, award_mode
      )
      values (v_activity_id, v_pid, v_awarded, v_twin_id, v_mode)
      on conflict (activity_id, profile_id) do update
        set points_awarded = excluded.points_awarded,
            twin_id = excluded.twin_id,
            award_mode = excluded.award_mode;

      update public.profiles
        set points_balance = points_balance + v_awarded
        where id = v_pid;

      v_hist_desc := p_type;
      if v_twin_nick is not null then
        v_hist_desc := v_hist_desc || ' · твінк: ' || v_twin_nick;
      end if;

      insert into public.history (type, actor_id, profile_id, activity_id, points, description)
      values ('points_award', auth.uid(), v_pid, v_activity_id, v_awarded, v_hist_desc);
    end loop;

  elsif p_profile_ids is not null then
    foreach v_pid in array p_profile_ids
    loop
      insert into public.activity_participants (activity_id, profile_id, points_awarded)
      values (v_activity_id, v_pid, v_base_points)
      on conflict (activity_id, profile_id) do nothing;

      update public.profiles
        set points_balance = points_balance + v_base_points
        where id = v_pid;

      insert into public.history (type, actor_id, profile_id, activity_id, points, description)
      values ('points_award', auth.uid(), v_pid, v_activity_id, v_base_points, p_type);
    end loop;
  end if;

  return v_activity_id;
end;
$$;

grant execute on function public.award_activity_points(text, date, text, uuid[], numeric, jsonb) to authenticated;
