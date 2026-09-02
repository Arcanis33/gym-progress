# GYM — дневник тренировок

Статическое веб-приложение для GitHub Pages с авторизацией и PostgreSQL-базой Supabase.

## Что уже реализовано

- вход по одноразовой email-ссылке;
- изоляция данных пользователей через Row Level Security;
- создание упражнений;
- смена изображения упражнения с телефона или компьютера;
- шесть единых групп мышц с наглядными анатомическими иконками;
- настройка состава «Дня ног» и «Дня спины»;
- создание, редактирование и удаление тренировок и подходов;
- история тренировок;
- объединённый график рабочего веса и повторений, отдельный график расчётного 1ПМ;
- компактные показатели лучшего веса, повторений и силы;
- адаптивная форма для телефона;
- автоматическая публикация на GitHub Pages.
- отдельный дневник питания для Артёма и Наташи;
- ввод еды обычной фразой, проверка состава и точный расчёт КБЖУ по базе продуктов;
- расчёт неизвестного продукта по указанной в сообщении ценности, например `50 г йогурта, 30 ккал на 100 г`;
- безопасный разбор текста через OpenRouter в Supabase Edge Function — секретный ключ не попадает в браузер.

## 1. Создание Supabase

1. Создайте бесплатный проект на [supabase.com](https://supabase.com/).
2. Откройте **SQL Editor**.
3. Скопируйте и выполните весь файл [`supabase/schema.sql`](./supabase/schema.sql).
4. В **Authentication → URL Configuration** добавьте URL сайта в **Redirect URLs**. Для локальной проверки добавьте также `http://localhost:8000/**`.
5. В **Project Settings → API** скопируйте Project URL и Publishable/anon key.

## 2. Настройка приложения

Откройте [`config.js`](./config.js) и замените два значения:

```js
window.GYM_CONFIG = {
  SUPABASE_URL: "https://ваш-проект.supabase.co",
  SUPABASE_ANON_KEY: "ваш-публичный-anon-ключ",
};
```

Publishable/anon key является публичным браузерным ключом. Его безопасность обеспечивают политики RLS. Никогда не помещайте в приложение `service_role` key.

## 3. Локальная проверка

Из корня проекта запустите любой статический сервер, например:

```powershell
python -m http.server 8000
```

Затем откройте `http://localhost:8000`. Не открывайте `index.html` через `file://`: email-переходы и ES-модули требуют HTTP.

## 4. GitHub Pages

1. Создайте GitHub-репозиторий и отправьте в него проект в ветку `main`.
2. Откройте **Settings → Pages**.
3. В **Build and deployment → Source** выберите **GitHub Actions**.
4. После выполнения workflow сайт появится по адресу `https://USERNAME.github.io/REPOSITORY/`.
5. Добавьте этот точный адрес в Supabase **Authentication → Redirect URLs**.

Workflow находится в [`.github/workflows/pages.yml`](./.github/workflows/pages.yml).

## 5. Питание и OpenRouter

1. Один раз выполните [`supabase/migrate_v6_nutrition.sql`](./supabase/migrate_v6_nutrition.sql) в **Supabase → SQL Editor**.
   Для существующей базы затем выполните [`supabase/migrate_v7_nutrition_facts.sql`](./supabase/migrate_v7_nutrition_facts.sql).
   После неё выполните [`supabase/migrate_v8_food_catalog_and_cooking_buffer.sql`](./supabase/migrate_v8_food_catalog_and_cooking_buffer.sql), чтобы сохранять консервативный запас калорий на масло и приготовление.
   Для дневника веса выполните [`supabase/migrate_v9_weight_entries.sql`](./supabase/migrate_v9_weight_entries.sql).
2. Разверните Edge Function из [`supabase/functions/parse-meal`](./supabase/functions/parse-meal).
3. В **Supabase → Edge Functions → Secrets** добавьте `OPENROUTER_API_KEY`. Ключ нельзя добавлять в `config.js` или коммитить в GitHub.
4. Необязательно задайте `OPENROUTER_MODEL`. По умолчанию используется бесплатный маршрутизатор `openrouter/free`.

Если функция ещё не развёрнута, интерфейс умеет локально разбирать простые записи из встроенного справочника. OpenRouter нужен для свободных формулировок, а итоговые калории и КБЖУ всегда считает приложение по значениям из таблицы `foods`.

## Модель данных

- `exercises` — личный справочник упражнений;
- `workout_day_exercises` — настраиваемая привязка упражнений к тренировочным дням;
- `workouts` — дата и заметка тренировки;
- `workout_sets` — упражнение, порядок, вес, повторения, RPE и признак разминки;
- `body_metrics` — подготовленная таблица для массы тела и других замеров.
- `foods` — общий справочник калорийности и КБЖУ на 100 г;
- `meals` — приёмы пищи пользователя с привязкой к Артёму или Наташе;
- `meal_items` — продукты и снимок пищевой ценности на момент записи.

Все пользовательские таблицы защищены RLS. Записи `workout_sets` доступны только владельцу связанной тренировки, а упражнение в подходе также обязано принадлежать этому пользователю.
