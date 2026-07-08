-- GRANT на profile_twins (без цього RLS не працює для authenticated)

grant select, insert, delete on public.profile_twins to authenticated;
