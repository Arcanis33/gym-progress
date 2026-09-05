-- Archiving preserves workout results and allows restoring an exercise.
alter table public.exercises add column if not exists archived_at timestamptz;
