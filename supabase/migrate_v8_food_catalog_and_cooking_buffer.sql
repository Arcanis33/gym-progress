-- Расширенный справочник загружается клиентом из data/foods.js.
-- В базе храним коэффициент запаса и снимок расчёта для каждого сохранённого блюда.
drop view if exists public.meal_summaries;

alter table public.foods
add column if not exists cooking_buffer_percent numeric(4,1) not null default 0;

alter table public.foods drop constraint if exists foods_cooking_buffer_percent_check;
alter table public.foods add constraint foods_cooking_buffer_percent_check
check (cooking_buffer_percent between 0 and 12);

alter table public.meal_items
add column if not exists cooking_buffer_percent numeric(4,1) not null default 0;

alter table public.meal_items drop constraint if exists meal_items_cooking_buffer_percent_check;
alter table public.meal_items add constraint meal_items_cooking_buffer_percent_check
check (cooking_buffer_percent between 0 and 12);

alter table public.meal_items drop column if exists calories;
alter table public.meal_items add column calories numeric(9,2)
generated always as (
  grams * kcal_per_100g / 100 * (1 + cooking_buffer_percent / 100)
) stored;

-- Уточняем базовые продукты и коэффициенты. Остальные продукты безопасно
-- сохраняются как снимки в meal_items, даже если их ещё нет в foods.
insert into public.foods
  (name, aliases, kcal_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, unit_grams, cooking_buffer_percent)
values
  ('Свинина готовая', array['свинина','свинины','свинину','мясо свинины'], 242,27.3,13.9,0,null,10),
  ('Огурец', array['огурец','огурца','огурцы','огурцов','огурчик','огурчики'], 15,.7,.1,3.6,null,0)
on conflict (user_id, name) do update set
  aliases = excluded.aliases,
  kcal_per_100g = excluded.kcal_per_100g,
  protein_per_100g = excluded.protein_per_100g,
  fat_per_100g = excluded.fat_per_100g,
  carbs_per_100g = excluded.carbs_per_100g,
  unit_grams = excluded.unit_grams,
  cooking_buffer_percent = excluded.cooking_buffer_percent;

update public.foods set cooking_buffer_percent = case name
  when 'Куриная грудка' then 8
  when 'Рис варёный' then 5
  when 'Яйцо куриное' then 5
  when 'Гречка варёная' then 5
  when 'Макароны варёные' then 5
  when 'Говядина готовая' then 10
  when 'Лосось готовый' then 10
  else 0
end
where user_id is null;

create or replace view public.meal_summaries
with (security_invoker = true) as
select m.id, m.user_id, m.athlete_id, m.name, m.eaten_at, m.source_text,
       coalesce(sum(i.calories), 0)::numeric(9,2) as total_kcal,
       coalesce(sum(i.grams * i.kcal_per_100g / 100), 0)::numeric(9,2) as base_kcal,
       coalesce(sum(i.calories - i.grams * i.kcal_per_100g / 100), 0)::numeric(9,2) as cooking_buffer_kcal,
       coalesce(sum(i.protein), 0)::numeric(9,2) as total_protein,
       coalesce(sum(i.fat), 0)::numeric(9,2) as total_fat,
       coalesce(sum(i.carbs), 0)::numeric(9,2) as total_carbs,
       coalesce(bool_and(i.macros_known), true) as macros_complete
from public.meals m
left join public.meal_items i on i.meal_id = m.id
group by m.id;

grant select on public.meal_summaries to authenticated;
