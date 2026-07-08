-- Дозволити гравцю додавати/видаляти власних твінків (без RPC)

drop policy if exists profile_twins_insert on public.profile_twins;
create policy profile_twins_insert
  on public.profile_twins
  for insert
  to authenticated
  with check (
    profile_id = auth.uid()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.status in ('pending', 'approved')
    )
  );

drop policy if exists profile_twins_delete on public.profile_twins;
create policy profile_twins_delete
  on public.profile_twins
  for delete
  to authenticated
  using (profile_id = auth.uid());

grant select, insert, delete on public.profile_twins to authenticated;

grant execute on function public.add_profile_twin(text) to authenticated;
grant execute on function public.remove_profile_twin(uuid) to authenticated;
