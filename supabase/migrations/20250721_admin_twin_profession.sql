-- Admin can update profession of any twin
create or replace function public.admin_set_twin_profession(p_twin_id uuid, p_profession smallint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if p_profession is not null and p_profession not between 1 and 10 then
    raise exception 'Невірна профа: %', p_profession;
  end if;

  update public.profile_twins set profession = p_profession where id = p_twin_id;
end;
$$;

grant execute on function public.admin_set_twin_profession(uuid, smallint) to authenticated;
