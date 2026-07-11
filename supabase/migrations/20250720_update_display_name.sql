
create or replace function public.update_display_name(p_display_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Не авторизовано' using errcode = '42501';
  end if;

  if not public.is_approved() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  p_display_name := trim(p_display_name);

  if p_display_name = '' then
    raise exception 'Імʼя не може бути порожнім';
  end if;

  if char_length(p_display_name) > 50 then
    raise exception 'Імʼя не може перевищувати 50 символів';
  end if;

  update public.profiles
  set display_name = p_display_name
  where id = v_uid;
end;
$$;

grant execute on function public.update_display_name(text) to authenticated;
