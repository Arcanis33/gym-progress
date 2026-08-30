-- Выполните один раз поверх схемы v1.
create table if not exists public.athletes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  slug text not null check (slug ~ '^[a-z0-9_-]+$'),
  name text not null check (char_length(name) between 1 and 80),
  created_at timestamptz not null default now(),
  unique (user_id, slug)
);

alter table public.exercises add column if not exists image_slug text;
alter table public.workouts add column if not exists day_type text;
alter table public.workout_sets add column if not exists athlete_id uuid references public.athletes(id) on delete cascade;
alter table public.workout_sets add column if not exists assistance_kg numeric(7,2);
alter table public.workout_sets add column if not exists next_step text;
alter table public.workout_sets add column if not exists comment text;

alter table public.athletes enable row level security;
drop policy if exists "Users manage own athletes" on public.athletes;
create policy "Users manage own athletes" on public.athletes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users manage sets of own workouts" on public.workout_sets;
create policy "Users manage sets of own workouts" on public.workout_sets
  for all using (
    exists (select 1 from public.workouts w where w.id = workout_id and w.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.workouts w where w.id = workout_id and w.user_id = auth.uid())
    and exists (select 1 from public.exercises e where e.id = exercise_id and e.user_id = auth.uid())
    and exists (select 1 from public.athletes a where a.id = athlete_id and a.user_id = auth.uid())
  );

revoke all on public.athletes from anon;
grant select, insert, update, delete on public.athletes to authenticated;

create index if not exists athletes_user_slug_idx on public.athletes(user_id, slug);
create index if not exists workout_sets_athlete_idx on public.workout_sets(athlete_id);
