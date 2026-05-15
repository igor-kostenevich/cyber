# Cyberpunk · Clan Progress Tracker

Трекер збору печаток клану Cyberpunk на R9.
Стек: **Nuxt 4 + Vue 3 (Composition API) + TypeScript + TailwindCSS v3 + Pinia + Supabase**.

## Швидкий старт

### 1. Встанови залежності

```bash
npm install
```

### 2. Налаштуй Supabase

Зайди у [Supabase Dashboard](https://supabase.com/dashboard) → твій проєкт → **SQL Editor**
та виконай скрипт `supabase/schema.sql` (одним блоком). Він створить:

- таблиці `participants`, `seal_entries`, `app_settings`,
- seed-рядок налаштувань `app_settings (id=1)`,
- RLS-політики:
  - анонім читає лише `approved`-учасників та їх записи,
  - анонім може створити заявку лише зі `status='pending'`,
  - решта операцій — тільки для авторизованих.

### 3. Створи адмін-користувача

Supabase Dashboard → **Authentication → Users → Add user → Create new user** (email + пароль).
Цей користувач (`authenticated`) зможе заходити в `/admin`.

### 4. Перевір `.env`

У корені вже створений `.env` з твоїми ключами:

```env
SUPABASE_URL=https://hvmvxkjijhyzjslixxxj.supabase.co
SUPABASE_KEY=sb_publishable_aohq96xxMnx6ucP4U9556w_Qvk8uvgK
```

Це `publishable`-ключ (не `service_role`) — його можна тримати у `public` runtimeConfig.

### 5. Запусти dev-сервер

```bash
npm run dev
```

→ <http://localhost:3000>

## Скрипти

- `npm run dev` — dev-сервер
- `npm run build` — production-збірка
- `npm run preview` — попередній перегляд production-збірки
- `npm run generate` — статична генерація
- `npm run typecheck` — перевірка типів (`vue-tsc`)

## Структура

```
app/
  app.vue                       # кореневий компонент
  assets/css/main.css           # Tailwind + кіберпанк-тема
  pages/
    index.vue                   # публічна сторінка з прогресом і учасниками
    admin.vue                   # адмін-панель (захищено middleware)
    login.vue                   # форма входу для адмінів
  layouts/default.vue
  middleware/auth.ts            # редірект /admin → /login
  plugins/auth.client.ts        # ініціалізація сесії з Supabase
  components/
    AppHero.vue
    ProgressCard.vue
    ParticipantCard.vue
    ParticipantDetailsModal.vue
    JoinRequestModal.vue
    AdminRequests.vue
    AdminParticipants.vue
    AdminParticipantEditModal.vue
    AdminEntryForm.vue
    ui/
      BaseButton.vue
      BaseModal.vue
      GlowCard.vue
      SkeletonLine.vue
      EmptyState.vue
  composables/
    useAppSupabaseClient.ts     # singleton supabase-client
    useProgress.ts              # підсумок прогресу клану
    useParticipantStats.ts      # статистика учасника
    useModal.ts                 # стан модалок
    useDateFormat.ts            # форматування дат (uk-UA)
  stores/
    auth.ts
    participants.ts
    entries.ts
    settings.ts
  types/index.ts
public/favicon.svg
supabase/schema.sql
nuxt.config.ts
tailwind.config.js
postcss.config.js
.env / .env.example
```

## Як працює доступ

- **Публічна сторінка `/`** — анонімне читання: бачимо лише `approved`-учасників та їх записи.
  Кнопка «Хочу допомогти» створює заявку зі `status='pending'`.
- **`/admin`** — захищено `middleware/auth.ts`. Якщо немає сесії — редірект на `/login?redirect=/admin`.
- **`/login`** — email/password через `supabase.auth.signInWithPassword`. Після успіху — на `/admin`.
- Усі CRUD-запити йдуть напряму з клієнта через `@supabase/supabase-js` (без власного `server/api/`).
  Безпека забезпечується **виключно** через RLS.

## Тема

- Темний кіберпанк-фон (radial + grid overlay).
- Шрифти: `Inter` для тексту, `Orbitron`/`Rajdhani` для заголовків (Google Fonts).
- Утиліти у `main.css`: `.glass`, `.glow`, `.card-cyber`, `.btn-primary`, `.btn-ghost`, `.input`, `.badge-*`.
- Палітра `cyber.*` + `neon.*` у `tailwind.config.js`.

## Чого свідомо не робимо

- Не використовуємо `service_role` ключ.
- Не створюємо `server/api/` — усі запити йдуть з клієнта.
- На публічній сторінці немає посилання на `/admin` (лише прямий URL).
