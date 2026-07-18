
-- Add profession to profiles (1=Воїн ... 10=Містік)
alter table public.profiles
  add column if not exists profession smallint check (profession between 1 and 10);

-- Add profession to profile_twins
alter table public.profile_twins
  add column if not exists profession smallint check (profession between 1 and 10);

-- Allow user to update their own twins (needed for profession update)
drop policy if exists profile_twins_update on public.profile_twins;
create policy profile_twins_update
  on public.profile_twins
  for update
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

grant update on public.profile_twins to authenticated;

-- Update handle_new_user to read profession from metadata
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nickname    text;
  v_profession  smallint;
begin
  v_nickname := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'nickname'), ''),
    split_part(new.email, '@', 1)
  );

  v_profession := nullif(trim(new.raw_user_meta_data ->> 'profession'), '')::smallint;

  insert into public.profiles (id, nickname, display_name, comment, profession)
  values (
    new.id,
    v_nickname,
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'comment'), ''),
    v_profession
  );

  insert into public.history (type, profile_id, description)
  values ('user_register', new.id, 'Реєстрація гравця: ' || v_nickname);

  return new;
end;
$$;

-- Admin can set profession for any user
create or replace function public.set_user_profession(p_profile_id uuid, p_profession smallint)
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

  update public.profiles set profession = p_profession where id = p_profile_id;
end;
$$;

grant execute on function public.set_user_profession(uuid, smallint) to authenticated;
