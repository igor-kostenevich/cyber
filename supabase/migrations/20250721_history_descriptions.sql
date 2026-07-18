
create or replace function public.set_user_status(p_profile_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nickname text;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;
  if p_status not in ('pending', 'approved', 'blocked') then
    raise exception 'Невірний статус: %', p_status;
  end if;

  select nickname into v_nickname from public.profiles where id = p_profile_id;

  update public.profiles set status = p_status where id = p_profile_id;

  insert into public.history (type, actor_id, profile_id, description)
  values (
    case when p_status = 'approved' then 'user_approve' else 'user_status' end,
    auth.uid(),
    p_profile_id,
    coalesce(v_nickname, '?') || ' → ' || p_status
  );
end;
$$;

create or replace function public.set_user_role(p_profile_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nickname text;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if p_role not in ('user', 'admin') then
    raise exception 'Можна призначити лише роль user або admin';
  end if;

  if exists (
    select 1 from public.profiles
    where id = p_profile_id and role = 'super_admin'
  ) then
    raise exception 'Неможливо змінити роль головного адміністратора';
  end if;

  if p_profile_id = auth.uid() then
    raise exception 'Не можна змінити власну роль';
  end if;

  select nickname into v_nickname from public.profiles where id = p_profile_id;

  update public.profiles set role = p_role where id = p_profile_id;

  if not found then
    raise exception 'Профіль не знайдено';
  end if;

  insert into public.history (type, actor_id, profile_id, description)
  values (
    'role_change',
    auth.uid(),
    p_profile_id,
    coalesce(v_nickname, '?') || ' → ' || p_role
  );
end;
$$;
