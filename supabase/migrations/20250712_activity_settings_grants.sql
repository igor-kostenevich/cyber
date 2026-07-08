-- Дозволи на RPC для налаштування балів за івенти

grant execute on function public.update_activity_type_points(text, numeric) to authenticated;

-- Нова сигнатура з p_points (стара 4-аргументна версія більше не потрібна)
drop function if exists public.award_activity_points(text, date, text, uuid[]);

grant execute on function public.award_activity_points(text, date, text, uuid[], numeric) to authenticated;

-- Пряме оновлення таблиці (резервний шлях з клієнта)
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
