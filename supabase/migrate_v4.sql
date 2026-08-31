-- Выполните один раз поверх схемы v3.
-- Нормализует группы мышц и добавляет настраиваемый состав тренировочных дней.

update public.exercises
set muscle_group = case
  when muscle_group = 'Корпус' then 'Пресс'
  when muscle_group = 'Трапеции' then 'Спина'
  else muscle_group
end
where muscle_group in ('Корпус', 'Трапеции');

alter table public.exercises drop constraint if exists exercises_muscle_group_check;
alter table public.exercises add constraint exercises_muscle_group_check
  check (muscle_group is null or muscle_group in ('Грудь', 'Пресс', 'Ноги', 'Спина', 'Плечи', 'Руки'));

create table if not exists public.workout_day_exercises (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  day_type text not null check (day_type in ('Ноги', 'Спина')),
  position integer not null default 0 check (position >= 0),
  created_at timestamptz not null default now(),
  unique (user_id, exercise_id, day_type)
);

create index if not exists workout_day_exercises_user_day_idx
  on public.workout_day_exercises(user_id, day_type, position);

alter table public.workout_day_exercises enable row level security;

drop policy if exists "Users manage own workout days" on public.workout_day_exercises;
create policy "Users manage own workout days" on public.workout_day_exercises
  for all using (auth.uid() = user_id) with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.exercises e
      where e.id = exercise_id and e.user_id = auth.uid()
    )
  );

revoke all on public.workout_day_exercises from anon;
grant select, insert, update, delete on public.workout_day_exercises to authenticated;

insert into public.workout_day_exercises (user_id, exercise_id, day_type, position)
select
  e.user_id,
  e.id,
  case when e.muscle_group in ('Ноги', 'Пресс') then 'Ноги' else 'Спина' end,
  row_number() over (
    partition by e.user_id, case when e.muscle_group in ('Ноги', 'Пресс') then 'Ноги' else 'Спина' end
    order by e.created_at, e.name
  ) - 1
from public.exercises e
on conflict (user_id, exercise_id, day_type) do nothing;
