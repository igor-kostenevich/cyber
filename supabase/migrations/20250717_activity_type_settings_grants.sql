-- GRANT на activity_type_settings (читання правил + upsert для адмінів через RLS)

grant select, insert, update on public.activity_type_settings to authenticated;
