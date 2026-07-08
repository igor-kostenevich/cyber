-- Корекція складу: додавання та списання
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

grant execute on function public.adjust_stock(uuid, integer) to authenticated;

notify pgrst, 'reload schema';
