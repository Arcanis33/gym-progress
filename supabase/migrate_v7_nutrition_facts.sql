-- Помечает записи, где пользователь указал только калории без полного БЖУ.
alter table public.meal_items
add column if not exists macros_known boolean not null default true;

create or replace view public.meal_summaries
with (security_invoker = true) as
select m.id, m.user_id, m.athlete_id, m.name, m.eaten_at, m.source_text,
       coalesce(sum(i.calories), 0)::numeric(9,2) as total_kcal,
       coalesce(sum(i.protein), 0)::numeric(9,2) as total_protein,
       coalesce(sum(i.fat), 0)::numeric(9,2) as total_fat,
       coalesce(sum(i.carbs), 0)::numeric(9,2) as total_carbs,
       coalesce(bool_and(i.macros_known), true) as macros_complete
from public.meals m
left join public.meal_items i on i.meal_id = m.id
group by m.id;

grant select on public.meal_summaries to authenticated;
