-- Выполните один раз поверх схемы v4.
-- Исправляет RLS для загрузки пользовательских изображений упражнений.

drop policy if exists "Users upload own exercise images" on storage.objects;
drop policy if exists "Users read own exercise images" on storage.objects;
drop policy if exists "Users update own exercise images" on storage.objects;
drop policy if exists "Users delete own exercise images" on storage.objects;

create policy "Users upload own exercise images" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'exercise-images'
    and split_part(name, '/', 1) = auth.uid()::text
  );

create policy "Users read own exercise images" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'exercise-images'
    and (owner_id = auth.uid()::text or split_part(name, '/', 1) = auth.uid()::text)
  );

create policy "Users update own exercise images" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'exercise-images'
    and (owner_id = auth.uid()::text or split_part(name, '/', 1) = auth.uid()::text)
  )
  with check (
    bucket_id = 'exercise-images'
    and split_part(name, '/', 1) = auth.uid()::text
  );

create policy "Users delete own exercise images" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'exercise-images'
    and (owner_id = auth.uid()::text or split_part(name, '/', 1) = auth.uid()::text)
  );
