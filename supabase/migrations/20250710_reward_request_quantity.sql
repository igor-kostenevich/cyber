-- Одна заявка з полем quantity замість N окремих рядків

alter table public.reward_requests
  add column if not exists quantity integer not null default 1 check (quantity > 0);

drop function if exists public.create_reward_request(uuid);
drop function if exists public.create_reward_request(uuid, integer);

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

grant execute on function public.create_reward_request(uuid, integer) to authenticated;

notify pgrst, 'reload schema';
