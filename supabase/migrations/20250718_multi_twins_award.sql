
alter table public.activity_participants
  add column if not exists include_main boolean not null default true;

alter table public.activity_participants
  add column if not exists twin_ids uuid[] not null default '{}';

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
  v_award         jsonb;
  v_pid           uuid;
  v_include_main  boolean;
  v_twin_ids      uuid[];
  v_twin_id       uuid;
  v_twin_nicks    text[] := '{}';
  v_awarded       numeric(10, 1);
  v_hist_desc     text;
  v_twin_json     jsonb;
  v_legacy_mode   text;
  v_legacy_twin   uuid;
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
      if v_pid is null then
        continue;
      end if;

      if not exists (
        select 1 from public.profiles
        where id = v_pid and status = 'approved'
      ) then
        raise exception 'Гравець не підтверджений: %', v_pid;
      end if;

      v_include_main := coalesce((v_award->>'include_main')::boolean, true);
      v_twin_ids := '{}';
      v_twin_nicks := '{}';

      if v_award ? 'twin_ids' and jsonb_typeof(v_award->'twin_ids') = 'array' then
        select coalesce(array_agg(t.id), '{}')
        into v_twin_ids
        from jsonb_array_elements_text(v_award->'twin_ids') elem
        join public.profile_twins t
          on t.id = elem.value::uuid
         and t.profile_id = v_pid;
      end if;

      if (v_twin_ids is null or cardinality(v_twin_ids) = 0) and v_award ? 'award_mode' then
        v_legacy_mode := coalesce(nullif(trim(v_award->>'award_mode'), ''), 'main');
        v_legacy_twin := nullif(v_award->>'twin_id', '')::uuid;

        if v_legacy_mode = 'main' then
          v_include_main := true;
        elsif v_legacy_mode = 'main_with_twin' then
          v_include_main := true;
          if v_legacy_twin is not null then
            v_twin_ids := array[v_legacy_twin];
          end if;
        elsif v_legacy_mode = 'twin_only' then
          v_include_main := false;
          if v_legacy_twin is not null then
            v_twin_ids := array[v_legacy_twin];
          end if;
        end if;
      end if;

      if not v_include_main and (v_twin_ids is null or cardinality(v_twin_ids) = 0) then
        raise exception 'Оберіть основного персонажа або твінків для %', v_pid;
      end if;

      if v_twin_ids is not null and cardinality(v_twin_ids) > 0 then
        foreach v_twin_id in array v_twin_ids
        loop
          if not exists (
            select 1 from public.profile_twins t
            where t.id = v_twin_id and t.profile_id = v_pid
          ) then
            raise exception 'Твінк не належить гравцю';
          end if;
        end loop;

        select coalesce(array_agg(t.nickname order by t.created_at), '{}')
        into v_twin_nicks
        from public.profile_twins t
        where t.id = any(v_twin_ids);
      end if;

      v_awarded := 0;
      if v_include_main then
        v_awarded := v_awarded + v_base_points;
      end if;

      if v_twin_ids is not null and cardinality(v_twin_ids) > 0 then
        v_awarded := v_awarded + round(v_base_points * 0.2, 1) * cardinality(v_twin_ids);
      end if;

      v_awarded := round(v_awarded, 1);

      insert into public.activity_participants (
        activity_id,
        profile_id,
        points_awarded,
        twin_id,
        award_mode,
        include_main,
        twin_ids
      )
      values (
        v_activity_id,
        v_pid,
        v_awarded,
        case when cardinality(v_twin_ids) = 1 then v_twin_ids[1] else null end,
        case
          when v_include_main and cardinality(v_twin_ids) > 0 then 'main_with_twin'
          when not v_include_main and cardinality(v_twin_ids) > 0 then 'twin_only'
          else 'main'
        end,
        v_include_main,
        coalesce(v_twin_ids, '{}')
      )
      on conflict (activity_id, profile_id) do update
        set points_awarded = excluded.points_awarded,
            twin_id = excluded.twin_id,
            award_mode = excluded.award_mode,
            include_main = excluded.include_main,
            twin_ids = excluded.twin_ids;

      update public.profiles
        set points_balance = points_balance + v_awarded
        where id = v_pid;

      v_hist_desc := p_type;
      if v_include_main then
        v_hist_desc := v_hist_desc || ' · основний';
      end if;
      if v_twin_nicks is not null and cardinality(v_twin_nicks) > 0 then
        v_hist_desc := v_hist_desc || ' · твінки: ' || array_to_string(v_twin_nicks, ', ');
      end if;

      insert into public.history (type, actor_id, profile_id, activity_id, points, description)
      values ('points_award', auth.uid(), v_pid, v_activity_id, v_awarded, v_hist_desc);
    end loop;

  elsif p_profile_ids is not null then
    foreach v_pid in array p_profile_ids
    loop
      insert into public.activity_participants (
        activity_id, profile_id, points_awarded, include_main, twin_ids
      )
      values (v_activity_id, v_pid, v_base_points, true, '{}')
      on conflict (activity_id, profile_id) do nothing;

      update public.profiles
        set points_balance = points_balance + v_base_points
        where id = v_pid;

      insert into public.history (type, actor_id, profile_id, activity_id, points, description)
      values (
        'points_award',
        auth.uid(),
        v_pid,
        v_activity_id,
        v_base_points,
        p_type || ' · основний'
      );
    end loop;
  end if;

  return v_activity_id;
end;
$$;

grant execute on function public.award_activity_points(text, date, text, uuid[], numeric, jsonb) to authenticated;
