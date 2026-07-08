-- Міграція: керування складом (create / update / delete нагород + зображення)
-- Виконати в Supabase → SQL Editor → Run

-- Прибрати стару сигнатуру update_reward (без назви та image_url)
drop function if exists public.update_reward(uuid, integer, numeric, boolean);

create or replace function public.update_reward(
  p_reward_id    uuid,
  p_name         text,
  p_price_points integer,
  p_is_available boolean,
  p_image_url    text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if p_name is not null and trim(p_name) = '' then
    raise exception 'Назва не може бути порожньою';
  end if;

  update public.rewards
    set name         = coalesce(nullif(trim(p_name), ''), name),
        price_points = coalesce(p_price_points, price_points),
        is_available = coalesce(p_is_available, is_available),
        image_url    = case when p_image_url is not null then nullif(trim(p_image_url), '') else image_url end
    where id = p_reward_id;

  if not found then
    raise exception 'Нагороду не знайдено';
  end if;

  insert into public.history (type, actor_id, reward_id, description)
  values ('reward_update', auth.uid(), p_reward_id, 'Оновлення нагороди');
end;
$$;

create or replace function public.create_reward(
  p_name          text,
  p_price_points  integer default 1,
  p_initial_stock integer default 0
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id         uuid;
  v_key        text;
  v_sort_order integer;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if trim(p_name) = '' then
    raise exception 'Назва не може бути порожньою';
  end if;
  if p_price_points is null or p_price_points < 0 then
    raise exception 'Ціна має бути >= 0';
  end if;
  if p_initial_stock is null or p_initial_stock < 0 then
    raise exception 'Початковий залишок має бути >= 0';
  end if;

  v_key := 'reward_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 12);
  select coalesce(max(sort_order), 0) + 10 into v_sort_order from public.rewards;

  insert into public.rewards (key, name, price_points, stock, is_available, sort_order)
  values (v_key, trim(p_name), p_price_points, p_initial_stock, true, v_sort_order)
  returning id into v_id;

  insert into public.history (type, actor_id, reward_id, description)
  values ('reward_update', auth.uid(), v_id, 'Створено нагороду: ' || trim(p_name));

  return v_id;
end;
$$;

create or replace function public.delete_reward(p_reward_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  select name into v_name from public.rewards where id = p_reward_id;
  if v_name is null then
    raise exception 'Нагороду не знайдено';
  end if;

  if exists (
    select 1 from public.reward_requests
    where reward_id = p_reward_id and status = 'pending'
  ) then
    raise exception 'Є активні заявки на цю нагороду — спочатку обробіть їх';
  end if;

  delete from public.rewards where id = p_reward_id;

  insert into public.history (type, actor_id, description)
  values ('reward_update', auth.uid(), 'Видалено нагороду: ' || v_name);
end;
$$;

grant execute on function public.update_reward(uuid, text, integer, boolean, text) to authenticated;
grant execute on function public.create_reward(text, integer, integer)          to authenticated;
grant execute on function public.delete_reward(uuid)                            to authenticated;

-- Розділити обʼєднані нагороди
update public.rewards
  set key = 'stone_armor', name = 'Камінна броня'
  where key = 'stone_diamond_armor';

insert into public.rewards (key, name, price_points, price_checks, stock, is_available, sort_order)
select 'diamond_armor', 'Алмазна броня', price_points, price_checks, 0, is_available, sort_order + 1
from public.rewards where key = 'stone_armor'
on conflict (key) do update set name = excluded.name;

update public.rewards
  set key = 'xuan_yuan_stone', name = 'Камінь Сюань Юань'
  where key = 'xuan_yuan_nuwa';

insert into public.rewards (key, name, price_points, price_checks, stock, is_available, sort_order)
select 'nuwa_stone', 'Камінь Нюйви', price_points, price_checks, 0, is_available, sort_order + 1
from public.rewards where key = 'xuan_yuan_stone'
on conflict (key) do update set name = excluded.name;

update public.rewards set name = 'Камінь заточки +10' where key = 'stone_10' and name in ('10 камені', '10 камні');
update public.rewards set name = 'Камінь заточки +11' where key = 'stone_11' and name in ('11 камені', '11 камні');

-- Storage для зображень
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'reward-images',
  'reward-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists reward_images_select on storage.objects;
create policy reward_images_select
  on storage.objects for select to public
  using (bucket_id = 'reward-images');

drop policy if exists reward_images_insert on storage.objects;
create policy reward_images_insert
  on storage.objects for insert to authenticated
  with check (bucket_id = 'reward-images' and public.is_admin());

drop policy if exists reward_images_update on storage.objects;
create policy reward_images_update
  on storage.objects for update to authenticated
  using (bucket_id = 'reward-images' and public.is_admin())
  with check (bucket_id = 'reward-images' and public.is_admin());

drop policy if exists reward_images_delete on storage.objects;
create policy reward_images_delete
  on storage.objects for delete to authenticated
  using (bucket_id = 'reward-images' and public.is_admin());

-- Оновити кеш PostgREST (на всяк випадок)
notify pgrst, 'reload schema';
