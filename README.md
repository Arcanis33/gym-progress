# GYM — дневник тренировок

Статическое веб-приложение для GitHub Pages с авторизацией и PostgreSQL-базой Supabase.

## Что уже реализовано

- вход по одноразовой email-ссылке;
- изоляция данных пользователей через Row Level Security;
- создание упражнений;
- создание, редактирование и удаление тренировок и подходов;
- история тренировок;
- общий объём и расчётный 1ПМ по формуле Эпли;
- базовые графики объёма и расчётного 1ПМ;
- адаптивная форма для телефона;
- автоматическая публикация на GitHub Pages.

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

## Модель данных

- `exercises` — личный справочник упражнений;
- `workouts` — дата и заметка тренировки;
- `workout_sets` — упражнение, порядок, вес, повторения, RPE и признак разминки;
- `body_metrics` — подготовленная таблица для массы тела и других замеров.

Все пользовательские таблицы защищены RLS. Записи `workout_sets` доступны только владельцу связанной тренировки, а упражнение в подходе также обязано принадлежать этому пользователю.
