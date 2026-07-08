-- Заявка на нагороду з кількістю
drop function if exists public.create_reward_request(uuid);

create or replace function public.create_reward_request(
  p_reward_id uuid,
  p_qty       integer default 1
)
returns integer
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
  i            integer;
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

  select coalesce(sum(price_points), 0) into v_reserved
  from public.reward_requests
  where profile_id = v_uid and status = 'pending';

  v_total := v_price * p_qty;

  if v_balance - v_reserved < v_total then
    raise exception 'Недостатньо балів';
  end if;

  for i in 1..p_qty loop
    insert into public.reward_requests (profile_id, reward_id, price_points, status)
    values (v_uid, p_reward_id, v_price, 'pending');
  end loop;

  insert into public.history (type, actor_id, profile_id, reward_id, points, amount, description)
  values (
    'reward_request',
    v_uid,
    v_uid,
    p_reward_id,
    v_total,
    p_qty,
    case when p_qty = 1 then 'Заявка на нагороду' else 'Заявки на нагороду: ' || p_qty end
  );

  return p_qty;
end;
$$;

grant execute on function public.create_reward_request(uuid, integer) to authenticated;

notify pgrst, 'reload schema';
