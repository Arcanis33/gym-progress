-- Выполните этот файл один раз в Supabase Dashboard → SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.athletes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  slug text not null check (slug ~ '^[a-z0-9_-]+$'),
  name text not null check (char_length(name) between 1 and 80),
  created_at timestamptz not null default now(),
  unique (user_id, slug)
);

create table if not exists public.exercises (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  name text not null check (char_length(name) between 1 and 120),
  muscle_group text check (muscle_group is null or char_length(muscle_group) <= 80),
  image_slug text check (image_slug is null or image_slug ~ '^[a-z0-9_-]+$'),
  image_url text,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  performed_at timestamptz not null,
  notes text check (notes is null or char_length(notes) <= 500),
  day_type text check (day_type is null or day_type in ('Ноги', 'Спина')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  set_order integer not null check (set_order > 0),
  weight_kg numeric(7,2) not null check (weight_kg >= 0 and weight_kg <= 2000),
  assistance_kg numeric(7,2) check (assistance_kg is null or assistance_kg between -2000 and 2000),
  reps integer not null check (reps > 0 and reps <= 1000),
  rpe numeric(3,1) check (rpe is null or rpe between 1 and 10),
  is_warmup boolean not null default false,
  next_step text check (next_step is null or char_length(next_step) <= 300),
  comment text check (comment is null or char_length(comment) <= 500),
  created_at timestamptz not null default now(),
  unique (workout_id, set_order)
);

create table if not exists public.body_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  measured_at timestamptz not null,
  bodyweight_kg numeric(6,2) check (bodyweight_kg is null or bodyweight_kg between 1 and 1000),
  notes text check (notes is null or char_length(notes) <= 500),
  created_at timestamptz not null default now()
);

create index if not exists workouts_user_date_idx on public.workouts(user_id, performed_at desc);
create index if not exists athletes_user_slug_idx on public.athletes(user_id, slug);
create index if not exists exercises_user_name_idx on public.exercises(user_id, name);
create index if not exists workout_sets_workout_idx on public.workout_sets(workout_id, set_order);
create index if not exists workout_sets_exercise_idx on public.workout_sets(exercise_id);
create index if not exists body_metrics_user_date_idx on public.body_metrics(user_id, measured_at desc);

alter table public.exercises enable row level security;
alter table public.athletes enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_sets enable row level security;
alter table public.body_metrics enable row level security;

create policy "Users manage own exercises" on public.exercises
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own athletes" on public.athletes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own workouts" on public.workouts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage sets of own workouts" on public.workout_sets
  for all using (
    exists (select 1 from public.workouts w where w.id = workout_id and w.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.workouts w where w.id = workout_id and w.user_id = auth.uid())
    and exists (select 1 from public.exercises e where e.id = exercise_id and e.user_id = auth.uid())
    and exists (select 1 from public.athletes a where a.id = athlete_id and a.user_id = auth.uid())
  );
create policy "Users manage own body metrics" on public.body_metrics
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists workouts_set_updated_at on public.workouts;
create trigger workouts_set_updated_at before update on public.workouts
for each row execute function public.set_updated_at();

revoke all on public.athletes, public.exercises, public.workouts, public.workout_sets, public.body_metrics from anon;
grant select, insert, update, delete on public.athletes, public.exercises, public.workouts, public.workout_sets, public.body_metrics to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('exercise-images', 'exercise-images', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create policy "Users upload own exercise images" on storage.objects for insert to authenticated
with check (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users update own exercise images" on storage.objects for update to authenticated
using (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users delete own exercise images" on storage.objects for delete to authenticated
using (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = auth.uid()::text);
