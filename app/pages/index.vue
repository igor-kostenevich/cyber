<script setup lang="ts">
useHead({ title: 'Cyberpunk — клан у CyberPW' })

const settings = useSettingsStore()
const auth = useAuthStore()
const profile = useProfileStore()

const clanName = computed(() => settings.data?.clan_name || 'Cyberpunk')

const primaryCta = computed(() => {
  if (!auth.isAuthenticated) return { to: '/login', label: 'Увійти' }
  if (profile.isAdmin) return { to: '/manage', label: 'Адмін-панель' }
  if (profile.isApproved) return { to: '/dashboard', label: 'Мій кабінет' }
  return { to: '/pending', label: 'Статус акаунта' }
})

const steps = [
  {
    num: '01',
    title: 'Насолода грою',
    text: 'Насамперед — гарно відпочити та отримати задоволення від CyberPW. Згадати дитяче захоплення, коли прогулювали школу заради гри, і зануритись у нього знову.',
    accent: 'cyan',
  },
  {
    num: '02',
    title: 'Підкорення карти',
    text: 'Головна амбіція — захопити карту світу. Поки ти спиш, ворог качається — тому спочатку будуємо міцну PvE-базу, а потім іде в хід PvP.',
    accent: 'violet',
  },
  {
    num: '03',
    title: 'Зростання команди',
    text: 'Постійно набираємо нових гравців. Досвідчені — одразу в бій, а новачкам — повне навчання з нуля. Головне — бажання грати разом.',
    accent: 'pink',
  },
]

const activityFeatures = [
  { icon: '⚔️', label: 'Серверні боси' },
  { icon: '🏟️', label: 'ГВГ' },
  { icon: '🐉', label: 'Рейдові боси' },
  { icon: '⚒️', label: 'Ремесло' },
  { icon: '🎁', label: 'Нагороди' },
  { icon: '📊', label: 'Рейтинг' },
]
</script>

<template>
  <div class="overflow-x-hidden">

    <!-- ═══ HERO ═══ -->
    <section class="relative w-full pt-16 pb-20 md:pt-24 md:pb-28 text-center">
      <div class="hero-glow pointer-events-none" aria-hidden="true" />

      <div class="relative z-10 container-page max-w-3xl mx-auto animate-fade-in">
        <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full glass text-xs uppercase tracking-[0.25em] text-cyan-300/80 mb-6">
          <span class="w-1.5 h-1.5 rounded-full bg-cyan-400 animate-pulse" />
          CyberPW · Клан {{ clanName }}
        </div>

        <h1 class="font-display text-5xl md:text-7xl leading-[1.1] mb-6">
          <span class="text-gradient-cyber">Ласкаво</span>
          <br>
          <span class="text-slate-100">просимо до клану</span>
        </h1>

        <p class="text-base md:text-lg text-slate-400 max-w-xl mx-auto leading-relaxed">
          Дружня команда гравців у CyberPW під командуванням
          <span class="text-cyan-200 font-semibold">Gremory</span>.
          Об'єднуємо тих, хто хоче провести час із задоволенням, розвинутись і разом підкорити карту світу.
        </p>

        <div class="mt-9 flex flex-wrap items-center justify-center gap-3">
          <a
            href="https://discord.gg/JyUhZSTGj"
            target="_blank"
            rel="noopener noreferrer"
            class="btn-primary text-sm py-3 px-6"
          >
            <svg class="w-4 h-4 shrink-0" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/></svg>
            Приєднатись
          </a>
          <NuxtLink
            v-if="!auth.isAuthenticated"
            to="/register"
            class="btn-ghost text-sm py-3 px-6"
          >
            Зареєструватись
          </NuxtLink>
          <NuxtLink
            v-else
            :to="primaryCta.to"
            class="btn-ghost text-sm py-3 px-6"
          >
            {{ primaryCta.label }}
          </NuxtLink>
        </div>
      </div>
    </section>

    <!-- ═══ GOALS — numbered steps ═══ -->
    <section class="container-page pb-20 md:pb-28">
      <div class="text-center mb-14">
        <div class="text-xs uppercase tracking-[0.3em] text-cyan-300/60 mb-2">Наша мета</div>
        <h2 class="font-display text-2xl md:text-3xl text-slate-100">Для чого ми тут?</h2>
      </div>

      <div class="max-w-3xl mx-auto space-y-0">
        <div
          v-for="(step, i) in steps"
          :key="step.num"
          class="step-row"
          :style="{ animationDelay: `${i * 120}ms` }"
        >
          <!-- connector line -->
          <div
            v-if="i < steps.length - 1"
            class="step-line"
            :class="`step-line--${step.accent}`"
          />

          <div class="grid gap-x-6 md:gap-x-8 pb-10" style="grid-template-columns: 5.5rem 1fr; grid-template-rows: auto auto;">
            <div
              class="step-num font-display row-span-2 self-start"
              :class="`step-num--${step.accent}`"
            >
              {{ step.num }}
            </div>
            <h3 class="font-display text-lg md:text-xl text-slate-100 self-center" style="line-height: 3rem;">
              {{ step.title }}
            </h3>
            <p class="text-sm text-slate-400 leading-relaxed max-w-md mt-1">
              {{ step.text }}
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- ═══ FOR EVERYONE — split layout ═══ -->
    <section class="py-16 md:py-20 border-y border-white/5 bg-white/[0.015]">
      <div class="container-page">
        <div class="text-center mb-12">
          <div class="text-xs uppercase tracking-[0.3em] text-cyan-300/60 mb-2">Команда</div>
          <h2 class="font-display text-2xl md:text-3xl text-slate-100">
            Місце є для кожного
          </h2>
        </div>

        <div class="grid md:grid-cols-2 gap-px max-w-3xl mx-auto rounded-2xl overflow-hidden border border-white/10 shadow-glow-sm">
          <!-- Newcomer -->
          <div class="bg-ink-800/40 backdrop-blur p-8">
            <div class="text-3xl mb-4">🌱</div>
            <h3 class="font-display text-lg text-cyan-100 mb-3">Ти новачок?</h3>
            <ul class="space-y-2.5 text-sm text-slate-400">
              <li class="flex items-start gap-2">
                <span class="text-cyan-400 mt-0.5 shrink-0">→</span>
                Навчимо всім механікам гри з нуля
              </li>
              <li class="flex items-start gap-2">
                <span class="text-cyan-400 mt-0.5 shrink-0">→</span>
                Допоможемо з екіпіровкою та прокачкою
              </li>
              <li class="flex items-start gap-2">
                <span class="text-cyan-400 mt-0.5 shrink-0">→</span>
                Гравці з 15+ роками досвіду поруч
              </li>
              <li class="flex items-start gap-2">
                <span class="text-cyan-400 mt-0.5 shrink-0">→</span>
                Дружня атмосфера без токсичності
              </li>
            </ul>
          </div>

          <!-- Veteran -->
          <div class="bg-violet-900/10 backdrop-blur p-8">
            <div class="text-3xl mb-4">⚡</div>
            <h3 class="font-display text-lg text-violet-200 mb-3">Ти ветеран?</h3>
            <ul class="space-y-2.5 text-sm text-slate-400">
              <li class="flex items-start gap-2">
                <span class="text-violet-400 mt-0.5 shrink-0">→</span>
                Твій досвід — цінність для всієї команди
              </li>
              <li class="flex items-start gap-2">
                <span class="text-violet-400 mt-0.5 shrink-0">→</span>
                Амбітні цілі: ГВГ, PvP, захоплення карти
              </li>
              <li class="flex items-start gap-2">
                <span class="text-violet-400 mt-0.5 shrink-0">→</span>
                Гравці різних вікових категорій
              </li>
              <li class="flex items-start gap-2">
                <span class="text-violet-400 mt-0.5 shrink-0">→</span>
                Можливість вести та наставляти інших
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- ═══ ACTIVITY SYSTEM — horizontal strip ═══ -->
    <section class="container-page py-20 md:py-24">
      <div class="max-w-4xl mx-auto">
        <div class="flex flex-col md:flex-row md:items-center gap-10 md:gap-16">
          <div class="md:w-2/5 shrink-0">
            <div class="text-xs uppercase tracking-[0.3em] text-cyan-300/60 mb-2">Для членів клану</div>
            <h2 class="font-display text-2xl md:text-3xl text-slate-100 mb-4">
              Система активності
            </h2>
            <p class="text-sm text-slate-400 leading-relaxed mb-4">
              Внутрішній трекер участі в кланових подіях. Бери участь, накопичуй Cyber-кредити
              і обмінюй на нагороди зі складу.
            </p>
            <p class="text-xs text-slate-500">
              Доступ після підтвердження адміністрацією.
            </p>
          </div>

          <div class="flex-1">
            <div class="grid grid-cols-3 gap-3">
              <div
                v-for="feat in activityFeatures"
                :key="feat.label"
                class="activity-chip"
              >
                <span class="text-2xl">{{ feat.icon }}</span>
                <span class="text-xs text-slate-400 font-medium">{{ feat.label }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ═══ DISCORD CTA — full-width banner ═══ -->
    <section class="relative overflow-hidden">
      <div class="discord-banner-bg pointer-events-none" aria-hidden="true" />
      <div class="relative z-10 container-page py-16 md:py-20 text-center">
        <div class="text-xs uppercase tracking-[0.3em] text-indigo-300/70 mb-3">Зв'язок</div>
        <h2 class="font-display text-3xl md:text-4xl text-slate-100 mb-3">
          Discord — серце клану
        </h2>
        <p class="text-sm text-slate-400 max-w-md mx-auto mb-8 leading-relaxed">
          Вся комунікація під час івентів, ГВГ і PvP-битв — тут.
          Заходь, знайомся з командою і будь у центрі подій.
        </p>
        <a
          href="https://discord.gg/JyUhZSTGj"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-2.5 bg-indigo-600 hover:bg-indigo-500 transition-colors text-white font-semibold text-sm py-3.5 px-8 rounded-xl shadow-[0_0_30px_rgba(99,102,241,0.4)] hover:shadow-[0_0_40px_rgba(99,102,241,0.6)]"
        >
          <svg class="w-5 h-5 shrink-0" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/></svg>
          Приєднатись
        </a>
      </div>
    </section>

  </div>
</template>


<style scoped>
.container-page {
  width: 100%;
  max-width: 80rem;
  margin-left: auto;
  margin-right: auto;
  padding-left: 1rem;
  padding-right: 1rem;
}
@media (min-width: 768px) {
  .container-page {
    padding-left: 2rem;
    padding-right: 2rem;
  }
}

/* Hero ambient glow */
.hero-glow {
  position: absolute;
  inset: 0;
  width: 100%;
  background:
    radial-gradient(ellipse 100% 80% at 50% -10%, rgba(56, 189, 248, 0.15), transparent 70%),
    radial-gradient(ellipse 60% 50% at 85% 70%, rgba(167, 139, 250, 0.10), transparent 70%);
}

/* Numbered steps */
.step-row {
  position: relative;
}

.step-line {
  position: absolute;
  left: 2.6rem;
  top: 3.2rem;
  bottom: 0;
  width: 1px;
  background: linear-gradient(to bottom, var(--line-color), transparent);
}
.step-line--cyan  { --line-color: rgba(56, 189, 248, 0.3); }
.step-line--violet { --line-color: rgba(167, 139, 250, 0.3); }
.step-line--pink  { --line-color: rgba(244, 114, 182, 0.3); }

.step-num {
  font-size: 3rem;
  line-height: 1;
  font-weight: 700;
  min-width: 3.5rem;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.step-num--cyan   { background-image: linear-gradient(135deg, #22d3ee, #38bdf8); }
.step-num--violet { background-image: linear-gradient(135deg, #a78bfa, #818cf8); }
.step-num--pink   { background-image: linear-gradient(135deg, #f472b6, #e879f9); }

/* Activity chips */
.activity-chip {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 0.875rem 0.5rem;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 0.75rem;
  transition: background 0.2s, border-color 0.2s;
}
.activity-chip:hover {
  background: rgba(56,189,248,0.06);
  border-color: rgba(56,189,248,0.25);
}

/* Discord banner */
.discord-banner-bg {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse 80% 80% at 50% 50%, rgba(99, 102, 241, 0.12), transparent),
    linear-gradient(to bottom, transparent, rgba(99, 102, 241, 0.05), transparent);
  border-top: 1px solid rgba(99, 102, 241, 0.15);
  border-bottom: 1px solid rgba(99, 102, 241, 0.15);
}
</style>
