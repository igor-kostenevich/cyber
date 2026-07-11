
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
  v_balance    numeric(10, 1);
  v_price      integer;
  v_stock      integer;
  v_available  boolean;
  v_reserved   numeric(10, 1);
  v_total      integer;
  v_status     text;
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
  if not coalesce(v_available, false) then
    raise exception 'Нагорода недоступна';
  end if;

  select coalesce(sum(price_points * quantity), 0) into v_reserved
  from public.reward_requests
  where profile_id = v_uid and status in ('pending', 'waiting');

  v_total := v_price * p_qty;

  if v_balance - v_reserved < v_total then
    raise exception 'Недостатньо балів';
  end if;

  if v_stock >= p_qty then
    v_status := 'pending';
  else
    v_status := 'waiting';
  end if;

  insert into public.reward_requests (profile_id, reward_id, price_points, quantity, status)
  values (v_uid, p_reward_id, v_price, p_qty, v_status)
  returning id into v_request_id;

  insert into public.history (type, actor_id, profile_id, reward_id, points, amount, description)
  values (
    'reward_request',
    v_uid,
    v_uid,
    p_reward_id,
    v_total,
    p_qty,
    case
      when v_status = 'waiting' and p_qty = 1 then 'Заявка в черзі (немає на складі)'
      when v_status = 'waiting' then 'Заявка в черзі (немає на складі) ×' || p_qty
      when p_qty = 1 then 'Заявка на нагороду'
      else 'Заявка на нагороду ×' || p_qty
    end
  );

  return v_request_id;
end;
$$;

create or replace function public.cancel_reward_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_req record;
begin
  select * into v_req
  from public.reward_requests
  where id = p_request_id;

  if not found then
    raise exception 'Заявку не знайдено';
  end if;

  if v_req.profile_id <> v_uid then
    raise exception 'Немає доступу' using errcode = '42501';
  end if;

  if v_req.status not in ('pending', 'waiting') then
    raise exception 'Можна скасувати лише заявку в очікуванні';
  end if;

  update public.reward_requests
  set status = 'rejected'
  where id = p_request_id;

  insert into public.history (type, actor_id, profile_id, reward_id, points, amount, description)
  values (
    'reward_request',
    v_uid,
    v_uid,
    v_req.reward_id,
    v_req.price_points * v_req.quantity,
    v_req.quantity,
    'Заявку скасовано користувачем'
  );
end;
$$;

grant execute on function public.cancel_reward_request(uuid) to authenticated;
