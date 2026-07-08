-- ============================================================================
--  Clan Activity System — окремий модуль (НЕ чіпає R9-схему в schema.sql)
--  Таблиці: profiles, activities, activity_participants, rewards,
--           reward_requests, history
--  Логіка нарахувань/списань/видач — через SECURITY DEFINER RPC (атомарність).
-- ============================================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------------------------
--  Tables
-- ----------------------------------------------------------------------------

create table if not exists public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  nickname       text not null unique,
  display_name   text,
  comment        text,
  role           text not null default 'user'
                   check (role in ('user', 'admin', 'super_admin')),
  status         text not null default 'pending'
                   check (status in ('pending', 'approved', 'blocked')),
  points_balance numeric(10, 1) not null default 0 check (points_balance >= 0),
  created_at     timestamptz not null default now()
);

create index if not exists profiles_status_idx on public.profiles (status);
create index if not exists profiles_role_idx on public.profiles (role);

create table if not exists public.activities (
  id            uuid primary key default gen_random_uuid(),
  type          text not null
                  check (type in ('server_boss', 'gvg', 'rb_boss', 'craft')),
  points        numeric(10, 1) not null check (points >= 0),
  description   text,
  activity_date date not null default current_date,
  created_by    uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now()
);

create index if not exists activities_date_idx on public.activities (activity_date desc);

create table if not exists public.activity_participants (
  id             uuid primary key default gen_random_uuid(),
  activity_id    uuid not null references public.activities (id) on delete cascade,
  profile_id     uuid not null references public.profiles (id) on delete cascade,
  points_awarded numeric(10, 1) not null default 0,
  created_at     timestamptz not null default now(),
  unique (activity_id, profile_id)
);

create index if not exists activity_participants_profile_idx
  on public.activity_participants (profile_id);
create index if not exists activity_participants_activity_idx
  on public.activity_participants (activity_id);

create table if not exists public.rewards (
  id           uuid primary key default gen_random_uuid(),
  key          text not null unique,
  name         text not null,
  image_url    text,
  price_points integer not null default 1 check (price_points >= 0),
  price_checks numeric(10, 3) not null default 0,
  stock        integer not null default 0 check (stock >= 0),
  is_available boolean not null default true,
  sort_order   integer not null default 0,
  created_at   timestamptz not null default now()
);

create index if not exists rewards_sort_idx on public.rewards (sort_order);

create table if not exists public.reward_requests (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles (id) on delete cascade,
  reward_id    uuid not null references public.rewards (id) on delete cascade,
  price_points integer not null,
  quantity     integer not null default 1 check (quantity > 0),
  status       text not null default 'pending'
                 check (status in ('pending', 'completed', 'rejected')),
  created_at   timestamptz not null default now(),
  resolved_at  timestamptz,
  resolved_by  uuid references public.profiles (id) on delete set null
);

create index if not exists reward_requests_profile_idx
  on public.reward_requests (profile_id);
create index if not exists reward_requests_status_idx
  on public.reward_requests (status);

create table if not exists public.history (
  id          uuid primary key default gen_random_uuid(),
  type        text not null check (type in (
                'points_award', 'points_spend', 'reward_grant', 'reward_request',
                'stock_add', 'user_register', 'user_approve', 'user_status',
                'role_change', 'reward_update'
              )),
  actor_id    uuid references public.profiles (id) on delete set null,
  profile_id  uuid references public.profiles (id) on delete set null,
  reward_id   uuid references public.rewards (id) on delete set null,
  activity_id uuid references public.activities (id) on delete set null,
  points      numeric(10, 1),
  amount      integer,
  description text,
  created_at  timestamptz not null default now()
);

create index if not exists history_profile_idx on public.history (profile_id);
create index if not exists history_created_idx on public.history (created_at desc);

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

-- ----------------------------------------------------------------------------
--  Helper functions (used by RLS) — SECURITY DEFINER, обходять RLS profiles
-- ----------------------------------------------------------------------------

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_approved()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and status = 'approved'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and status = 'approved'
      and role in ('admin', 'super_admin')
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and status = 'approved'
      and role = 'super_admin'
  );
$$;

-- ----------------------------------------------------------------------------
--  Trigger: створення профілю після реєстрації (signUp)
-- ----------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nickname text;
begin
  v_nickname := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'nickname'), ''),
    split_part(new.email, '@', 1)
  );

  insert into public.profiles (id, nickname, display_name, comment)
  values (
    new.id,
    v_nickname,
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'comment'), '')
  );

  insert into public.history (type, profile_id, description)
  values ('user_register', new.id, 'Реєстрація гравця: ' || v_nickname);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

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

-- ----------------------------------------------------------------------------
--  RPC: нарахування балів за активність (admin)
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

-- ----------------------------------------------------------------------------
--  RPC: заявка на нагороду (player)
-- ----------------------------------------------------------------------------

create or replace function public.create_reward_request(
  p_reward_id uuid,
  p_qty       integer default 1
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid        uuid := auth.uid();
  v_balance    integer;
  v_price      integer;
  v_stock      integer;
  v_available  boolean;
  v_reserved   integer;
  v_total      integer;
  v_request_id uuid;
begin
  if not public.is_approved() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  if p_qty is null or p_qty <= 0 then
    raise exception 'Кількість має бути більшою за 0';
  end if;

  select points_balance into v_balance from public.profiles where id = v_uid;

  select price_points, stock, is_available
    into v_price, v_stock, v_available
    from public.rewards
    where id = p_reward_id;

  if v_price is null then
    raise exception 'Нагороду не знайдено';
  end if;
  if not v_available or v_stock <= 0 then
    raise exception 'Нагороди немає на складі';
  end if;

  if exists (
    select 1 from public.reward_requests
    where profile_id = v_uid and reward_id = p_reward_id and status = 'pending'
  ) then
    raise exception 'Заявка на цю нагороду вже існує';
  end if;

  select coalesce(sum(price_points * quantity), 0) into v_reserved
  from public.reward_requests
  where profile_id = v_uid and status = 'pending';

  v_total := v_price * p_qty;

  if v_balance - v_reserved < v_total then
    raise exception 'Недостатньо балів';
  end if;

  insert into public.reward_requests (profile_id, reward_id, price_points, quantity, status)
  values (v_uid, p_reward_id, v_price, p_qty, 'pending')
  returning id into v_request_id;

  insert into public.history (type, actor_id, profile_id, reward_id, points, amount, description)
  values (
    'reward_request',
    v_uid,
    v_uid,
    p_reward_id,
    v_total,
    p_qty,
    case when p_qty = 1 then 'Заявка на нагороду' else 'Заявка на нагороду ×' || p_qty end
  );

  return v_request_id;
end;
$$;

-- ----------------------------------------------------------------------------
--  RPC: видача нагороди (admin) — атомарно: списання балів + склад -1
-- ----------------------------------------------------------------------------

create or replace function public.grant_reward_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req     public.reward_requests%rowtype;
  v_stock   integer;
  v_balance integer;
  v_total   integer;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  select * into v_req from public.reward_requests where id = p_request_id for update;
  if v_req.id is null then
    raise exception 'Заявку не знайдено';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Заявку вже опрацьовано';
  end if;

  v_total := v_req.price_points * v_req.quantity;

  select stock into v_stock from public.rewards where id = v_req.reward_id for update;
  if v_stock < v_req.quantity then
    raise exception 'Недостатньо нагород на складі';
  end if;

  select points_balance into v_balance from public.profiles where id = v_req.profile_id for update;
  if v_balance < v_total then
    raise exception 'У гравця недостатньо балів';
  end if;

  update public.profiles
    set points_balance = points_balance - v_total
    where id = v_req.profile_id;

  update public.rewards
    set stock = stock - v_req.quantity
    where id = v_req.reward_id;

  update public.reward_requests
    set status = 'completed', resolved_at = now(), resolved_by = auth.uid()
    where id = p_request_id;

  insert into public.history (type, actor_id, profile_id, reward_id, points, description)
  values ('points_spend', auth.uid(), v_req.profile_id, v_req.reward_id, v_total, 'Списання балів за нагороду');

  insert into public.history (type, actor_id, profile_id, reward_id, points, amount, description)
  values (
    'reward_grant',
    auth.uid(),
    v_req.profile_id,
    v_req.reward_id,
    v_total,
    v_req.quantity,
    case when v_req.quantity = 1 then 'Видача нагороди' else 'Видача нагороди ×' || v_req.quantity end
  );
end;
$$;

-- ----------------------------------------------------------------------------
--  RPC: відхилення заявки (admin)
-- ----------------------------------------------------------------------------

create or replace function public.reject_reward_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req public.reward_requests%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;

  select * into v_req from public.reward_requests where id = p_request_id for update;
  if v_req.id is null then
    raise exception 'Заявку не знайдено';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Заявку вже опрацьовано';
  end if;

  update public.reward_requests
    set status = 'rejected', resolved_at = now(), resolved_by = auth.uid()
    where id = p_request_id;

  insert into public.history (type, actor_id, profile_id, reward_id, points, description)
  values ('reward_request', auth.uid(), v_req.profile_id, v_req.reward_id, v_req.price_points, 'Заявку відхилено');
end;
$$;

-- ----------------------------------------------------------------------------
--  RPC: склад (admin)
-- ----------------------------------------------------------------------------

create or replace function public.adjust_stock(p_reward_id uuid, p_delta integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;
  if p_delta is null or p_delta = 0 then
    raise exception 'Зміна має бути відмінною від 0';
  end if;

  update public.rewards
    set stock = greatest(0, stock + p_delta)
    where id = p_reward_id;

  if not found then
    raise exception 'Нагороду не знайдено';
  end if;

  insert into public.history (type, actor_id, reward_id, amount, description)
  values (
    'stock_add',
    auth.uid(),
    p_reward_id,
    p_delta,
    case when p_delta > 0 then 'Поповнення складу' else 'Списання зі складу' end
  );
end;
$$;

-- Залишаємо add_stock для сумісності (лише додавання)
create or replace function public.add_stock(p_reward_id uuid, p_qty integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_qty is null or p_qty <= 0 then
    raise exception 'Кількість має бути більшою за 0';
  end if;
  perform public.adjust_stock(p_reward_id, p_qty);
end;
$$;

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

-- ----------------------------------------------------------------------------
--  RPC: керування гравцями (admin / super_admin)
-- ----------------------------------------------------------------------------

create or replace function public.set_user_status(p_profile_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Недостатньо прав' using errcode = '42501';
  end if;
  if p_status not in ('pending', 'approved', 'blocked') then
    raise exception 'Невірний статус: %', p_status;
  end if;

  update public.profiles set status = p_status where id = p_profile_id;

  insert into public.history (type, actor_id, profile_id, description)
  values (
    case when p_status = 'approved' then 'user_approve' else 'user_status' end,
    auth.uid(),
    p_profile_id,
    'Статус гравця: ' || p_status
  );
end;
$$;

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

-- ----------------------------------------------------------------------------
--  Seed: фіксований список нагород
-- ----------------------------------------------------------------------------

insert into public.rewards (key, name, price_points, price_checks, stock, is_available, sort_order)
values
  ('sword_summer_wind', 'Меч літнього вітру',     12, 12,    0, true,  10),
  ('stone_armor', 'Камінна броня',                 20, 20,    0, true,  20),
  ('diamond_armor', 'Алмазна броня',               20, 20,    0, true,  21),
  ('pks', 'ПКС',                                   30, 30,    0, true,  30),
  ('xuan_yuan_stone', 'Камінь Сюань Юань',          8, 8,     0, true,  40),
  ('nuwa_stone', 'Камінь Нюйви',                     8, 8,     0, true,  41),
  ('stone_10', 'Камінь заточки +10',                 1, 1,     0, true,  50),
  ('stone_11', 'Камінь заточки +11',                 5, 5,     0, true,  60),
  ('thor_chest', 'Скриня Тора',                      1, 0.125, 0, true,  70),
  ('golden_eggs', 'Золоті яйця',                     1, 0.08,  0, true,  80),
  ('grand_master_stone', 'Камінь великого майстра',  5, 5,     0, true,  90),
  ('knife', 'Ніж',                                    1, 0.2,   0, true, 100),
  ('medal', 'Медаль',                                 1, 0.1,   0, true, 110),
  ('glory_order', 'Орден слави',                    160, 160,   0, true, 120),
  ('immortal_stone', 'Камінь безсмертних',            1, 0.005, 0, true, 130)
on conflict (key) do update
  set name = excluded.name,
      price_points = excluded.price_points,
      sort_order = excluded.sort_order;

-- Міграція: розділити обʼєднані нагороди в існуючій БД
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

-- ----------------------------------------------------------------------------
--  Grants
-- ----------------------------------------------------------------------------

grant usage on schema public to anon, authenticated;

grant select on public.profiles               to authenticated;
grant select on public.activities             to authenticated;
grant select on public.activity_participants  to authenticated;
grant select on public.rewards                to authenticated;
grant select on public.reward_requests        to authenticated;
grant select on public.history                to authenticated;
grant select, insert, update on public.activity_type_settings to authenticated;
grant select, insert, delete on public.profile_twins to authenticated;

grant execute on function public.current_user_role()            to anon, authenticated;
grant execute on function public.is_approved()                  to anon, authenticated;
grant execute on function public.is_admin()                     to anon, authenticated;
grant execute on function public.is_super_admin()               to anon, authenticated;
grant execute on function public.update_activity_type_points(text, numeric) to authenticated;
grant execute on function public.award_activity_points(text, date, text, uuid[], numeric) to authenticated;
grant execute on function public.create_reward_request(uuid, integer) to authenticated;
grant execute on function public.grant_reward_request(uuid)     to authenticated;
grant execute on function public.reject_reward_request(uuid)    to authenticated;
grant execute on function public.add_stock(uuid, integer)       to authenticated;
grant execute on function public.adjust_stock(uuid, integer)    to authenticated;
grant execute on function public.update_reward(uuid, text, integer, boolean, text) to authenticated;
grant execute on function public.create_reward(text, integer, integer)          to authenticated;
grant execute on function public.delete_reward(uuid)                            to authenticated;
grant execute on function public.set_user_status(uuid, text)    to authenticated;
grant execute on function public.set_user_role(uuid, text)      to authenticated;

-- ----------------------------------------------------------------------------
--  RLS
-- ----------------------------------------------------------------------------

alter table public.profiles              enable row level security;
alter table public.activities            enable row level security;
alter table public.activity_participants enable row level security;
alter table public.rewards               enable row level security;
alter table public.reward_requests       enable row level security;
alter table public.history               enable row level security;
alter table public.activity_type_settings enable row level security;

-- profiles: свій рядок бачить кожен authenticated; усі профілі — лише approved/admin.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid() or public.is_approved());

-- activities / activity_participants / rewards: читання для approved.
drop policy if exists activities_select on public.activities;
create policy activities_select
  on public.activities
  for select
  to authenticated
  using (public.is_approved());

drop policy if exists activity_participants_select on public.activity_participants;
create policy activity_participants_select
  on public.activity_participants
  for select
  to authenticated
  using (public.is_approved());

drop policy if exists rewards_select on public.rewards;
create policy rewards_select
  on public.rewards
  for select
  to authenticated
  using (public.is_approved());

-- reward_requests: свої — гравцю, усі — адміну.
drop policy if exists reward_requests_select on public.reward_requests;
create policy reward_requests_select
  on public.reward_requests
  for select
  to authenticated
  using (profile_id = auth.uid() or public.is_admin());

-- history: своя — гравцю, уся — адміну.
drop policy if exists history_select on public.history;
create policy history_select
  on public.history
  for select
  to authenticated
  using (profile_id = auth.uid() or public.is_admin());

drop policy if exists activity_type_settings_select on public.activity_type_settings;
create policy activity_type_settings_select
  on public.activity_type_settings
  for select
  to authenticated
  using (true);

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

-- УВАГА: усі мутації (insert/update/delete) йдуть ВИКЛЮЧНО через RPC вище
-- (SECURITY DEFINER). Прямих policy на запис немає → прямий запис заборонено.

-- ----------------------------------------------------------------------------
--  Промоут існуючого R9-адміна у super_admin (виконати ОДИН раз вручну).
--  Профіль для акаунтів, створених ДО тригера, треба додати окремо:
-- ----------------------------------------------------------------------------
-- insert into public.profiles (id, nickname, role, status)
-- select id, split_part(email, '@', 1), 'super_admin', 'approved'
-- from auth.users
-- where email = 'YOUR_ADMIN_EMAIL'
-- on conflict (id) do update set role = 'super_admin', status = 'approved';

-- ----------------------------------------------------------------------------
--  Storage: зображення нагород (публічне читання, завантаження — admin)
-- ----------------------------------------------------------------------------

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
  on storage.objects
  for select
  to public
  using (bucket_id = 'reward-images');

drop policy if exists reward_images_insert on storage.objects;
create policy reward_images_insert
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'reward-images' and public.is_admin());

drop policy if exists reward_images_update on storage.objects;
create policy reward_images_update
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'reward-images' and public.is_admin())
  with check (bucket_id = 'reward-images' and public.is_admin());

drop policy if exists reward_images_delete on storage.objects;
create policy reward_images_delete
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'reward-images' and public.is_admin());
