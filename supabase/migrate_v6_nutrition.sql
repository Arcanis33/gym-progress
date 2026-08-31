-- Питание: выполните один раз в Supabase Dashboard -> SQL Editor.
create table if not exists public.foods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  aliases text[] not null default '{}',
  kcal_per_100g numeric(7,2) not null check (kcal_per_100g between 0 and 1000),
  protein_per_100g numeric(6,2) not null default 0 check (protein_per_100g between 0 and 100),
  fat_per_100g numeric(6,2) not null default 0 check (fat_per_100g between 0 and 100),
  carbs_per_100g numeric(6,2) not null default 0 check (carbs_per_100g between 0 and 100),
  unit_grams numeric(7,2) check (unit_grams is null or unit_grams > 0),
  created_at timestamptz not null default now(),
  unique nulls not distinct (user_id, name)
);

create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  athlete_id uuid not null references public.athletes(id) on delete cascade,
  name text not null default 'Приём пищи' check (char_length(name) between 1 and 80),
  eaten_at timestamptz not null default now(),
  source_text text check (source_text is null or char_length(source_text) <= 600),
  created_at timestamptz not null default now()
);

create table if not exists public.meal_items (
  id uuid primary key default gen_random_uuid(),
  meal_id uuid not null references public.meals(id) on delete cascade,
  food_id uuid references public.foods(id) on delete set null,
  position integer not null default 0 check (position >= 0),
  food_name text not null check (char_length(food_name) between 1 and 120),
  grams numeric(8,2) not null check (grams > 0 and grams <= 10000),
  kcal_per_100g numeric(7,2) not null check (kcal_per_100g between 0 and 1000),
  protein_per_100g numeric(6,2) not null default 0,
  fat_per_100g numeric(6,2) not null default 0,
  carbs_per_100g numeric(6,2) not null default 0,
  calories numeric(9,2) generated always as (grams * kcal_per_100g / 100) stored,
  protein numeric(9,2) generated always as (grams * protein_per_100g / 100) stored,
  fat numeric(9,2) generated always as (grams * fat_per_100g / 100) stored,
  carbs numeric(9,2) generated always as (grams * carbs_per_100g / 100) stored,
  created_at timestamptz not null default now()
);

create index if not exists meals_user_athlete_date_idx on public.meals(user_id, athlete_id, eaten_at desc);
create index if not exists meal_items_meal_idx on public.meal_items(meal_id, position);
create index if not exists foods_user_name_idx on public.foods(user_id, name);

alter table public.foods enable row level security;
alter table public.meals enable row level security;
alter table public.meal_items enable row level security;

create policy "Authenticated users read food catalog" on public.foods for select to authenticated
using (user_id is null or user_id = auth.uid());
create policy "Users create own foods" on public.foods for insert to authenticated
with check (user_id = auth.uid());
create policy "Users update own foods" on public.foods for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users delete own foods" on public.foods for delete to authenticated
using (user_id = auth.uid());

create policy "Users manage own meals" on public.meals for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid() and exists (
  select 1 from public.athletes a where a.id = athlete_id and a.user_id = auth.uid()
));
create policy "Users manage items of own meals" on public.meal_items for all to authenticated
using (exists (select 1 from public.meals m where m.id = meal_id and m.user_id = auth.uid()))
with check (exists (select 1 from public.meals m where m.id = meal_id and m.user_id = auth.uid()));

grant select, insert, update, delete on public.foods, public.meals, public.meal_items to authenticated;
revoke all on public.foods, public.meals, public.meal_items from anon;

create or replace view public.meal_summaries
with (security_invoker = true) as
select m.id, m.user_id, m.athlete_id, m.name, m.eaten_at, m.source_text,
       coalesce(sum(i.calories), 0)::numeric(9,2) as total_kcal,
       coalesce(sum(i.protein), 0)::numeric(9,2) as total_protein,
       coalesce(sum(i.fat), 0)::numeric(9,2) as total_fat,
       coalesce(sum(i.carbs), 0)::numeric(9,2) as total_carbs
from public.meals m
left join public.meal_items i on i.meal_id = m.id
group by m.id;
grant select on public.meal_summaries to authenticated;

insert into public.foods (name, aliases, kcal_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, unit_grams) values
('Куриная грудка', array['курица','курицы','куриная грудка','куриную грудку'], 165,31,3.6,0,null),
('Рис варёный', array['рис','риса','вареный рис','варёный рис'], 130,2.7,.3,28.2,null),
('Овощной салат', array['салат','салата','овощной салат'], 35,1.5,.5,6,null),
('Яйцо куриное', array['яйцо','яйца','яиц'], 143,12.6,9.5,.7,50),
('Хлеб', array['хлеб','хлеба'], 250,8,3,49,null),
('Помидоры', array['помидор','помидора','помидоры','томаты'], 18,.9,.2,3.9,null),
('Гречка варёная', array['гречка','гречки','гречу'], 110,4.2,1.1,21.3,null),
('Макароны варёные', array['макароны','макарон','паста','пасты'], 131,5,1.1,25,null),
('Говядина готовая', array['говядина','говядины'], 250,26,15,0,null),
('Лосось готовый', array['лосось','лосося','семга','сёмга'], 208,20,13,0,null),
('Творог 5%', array['творог','творога'], 121,17,5,1.8,null),
('Банан', array['банан','банана','бананы'], 89,1.1,.3,22.8,null),
('Овсяная каша', array['овсянка','овсянки','овсяная каша'], 88,3,1.7,15,null),
('Картофель варёный', array['картофель','картофеля','картошка','картошки'], 82,2,.4,16.7,null),
('Молоко 2,5%', array['молоко','молока'], 52,2.8,2.5,4.7,null),
('Оливковое масло', array['оливковое масло','масло'], 884,0,100,0,null)
on conflict (user_id, name) do nothing;
