-- R9: мутації лише для super_admin; ролі: admin може призначати admin

-- participants
drop policy if exists participants_insert_authenticated on public.participants;
create policy participants_insert_authenticated
  on public.participants for insert to authenticated
  with check (public.is_super_admin() or (public.is_approved() and status = 'pending'));

drop policy if exists participants_update_authenticated on public.participants;
create policy participants_update_authenticated
  on public.participants for update to authenticated
  using (public.is_super_admin()) with check (public.is_super_admin());

drop policy if exists participants_delete_authenticated on public.participants;
create policy participants_delete_authenticated
  on public.participants for delete to authenticated
  using (public.is_super_admin());

-- seal_entries
drop policy if exists seal_entries_insert_authenticated on public.seal_entries;
create policy seal_entries_insert_authenticated
  on public.seal_entries for insert to authenticated
  with check (public.is_super_admin());

drop policy if exists seal_entries_update_authenticated on public.seal_entries;
create policy seal_entries_update_authenticated
  on public.seal_entries for update to authenticated
  using (public.is_super_admin()) with check (public.is_super_admin());

drop policy if exists seal_entries_delete_authenticated on public.seal_entries;
create policy seal_entries_delete_authenticated
  on public.seal_entries for delete to authenticated
  using (public.is_super_admin());

-- app_settings
drop policy if exists app_settings_update_authenticated on public.app_settings;
create policy app_settings_update_authenticated
  on public.app_settings for update to authenticated
  using (public.is_super_admin()) with check (public.is_super_admin());

-- set_user_role: admin і super_admin можуть призначати user/admin (не super_admin)
create or replace function public.set_user_role(p_profile_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
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

  update public.profiles set role = p_role where id = p_profile_id;

  if not found then
    raise exception 'Профіль не знайдено';
  end if;

  insert into public.history (type, actor_id, profile_id, description)
  values ('role_change', auth.uid(), p_profile_id, 'Нова роль: ' || p_role);
end;
$$;

notify pgrst, 'reload schema';
