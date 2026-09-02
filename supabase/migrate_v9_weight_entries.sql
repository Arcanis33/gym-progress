-- Ежедневный дневник веса для каждого спортсмена.
create table if not exists public.weight_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  recorded_on date not null default current_date,
  weight_kg numeric(5,1) not null check (weight_kg between 20 and 500),
  note text check (note is null or char_length(note) <= 160),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (athlete_id, recorded_on)
);

create index if not exists weight_entries_athlete_date_idx
on public.weight_entries(athlete_id, recorded_on desc);

alter table public.weight_entries enable row level security;

drop policy if exists "Users manage own weight entries" on public.weight_entries;
create policy "Users manage own weight entries" on public.weight_entries
for all to authenticated
using (user_id = auth.uid())
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.athletes a
    where a.id = athlete_id and a.user_id = auth.uid()
  )
);

grant select, insert, update, delete on public.weight_entries to authenticated;
revoke all on public.weight_entries from anon;
