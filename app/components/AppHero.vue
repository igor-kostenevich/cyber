<script setup lang="ts">
const settings = useSettingsStore()

const logoSrc = computed(() => settings.data?.logo_url || '/logo.jpg')

const nick = 'lyntik'
const copied = ref<boolean>(false)
let resetTimer: ReturnType<typeof setTimeout> | null = null

const copyNick = async (): Promise<void> => {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(nick)
    }
    else {
      const ta = document.createElement('textarea')
      ta.value = nick
      ta.style.position = 'fixed'
      ta.style.opacity = '0'
      document.body.appendChild(ta)
      ta.select()
      document.execCommand('copy')
      document.body.removeChild(ta)
    }
    copied.value = true
    if (resetTimer) clearTimeout(resetTimer)
    resetTimer = setTimeout(() => (copied.value = false), 1800)
  }
  catch (e) {
    console.error('[AppHero] Не вдалося скопіювати нік:', e)
  }
}

onBeforeUnmount(() => {
  if (resetTimer) clearTimeout(resetTimer)
})
</script>

<template>
  <section class="container-page pt-10 pb-8 md:pt-14 md:pb-10">
    <div class="flex flex-col items-center text-center max-w-3xl mx-auto">
      <div class="relative mb-6">
        <div class="absolute inset-0 rounded-full bg-gradient-to-tr from-cyan-400/40 via-sky-400/30 to-violet-500/40 blur-2xl opacity-70" />
        <div class="relative h-28 w-28 md:h-36 md:w-36 rounded-full overflow-hidden border border-white/20 shadow-glow-lg bg-ink-800">
          <img
            :src="logoSrc"
            alt="Cyberpunk clan logo"
            class="h-full w-full object-cover"
            loading="eager"
            decoding="async"
          >
          <div class="pointer-events-none absolute inset-0 rounded-full bg-gradient-to-tr from-cyan-400/10 via-transparent to-violet-500/10" />
        </div>
      </div>

      <div class="inline-flex items-center gap-2 mb-4 px-3 py-1.5 rounded-full glass text-xs font-medium tracking-widest uppercase text-cyan-300">
        <span class="h-1.5 w-1.5 rounded-full bg-cyan-400 animate-pulse" />
        Клан · {{ settings.data?.clan_name || 'Cyberpunk' }}
      </div>

      <h1 class="font-display text-4xl md:text-6xl font-black leading-tight">
        <span class="text-gradient-cyber">
          {{ settings.data?.title || 'Збір Лунтіку на R9' }}
        </span>
      </h1>

      <p class="mt-4 text-slate-300 text-sm md:text-base max-w-2xl leading-relaxed">
        Хочеш зробити клан сильніше і заробити — тобі до мене.
        Скинь <span class="text-amber-200 font-semibold">печать владики</span>
        і отримай <span class="text-emerald-200 font-semibold">40&nbsp;кк</span> на пошту.
      </p>

      <button
        type="button"
        class="nick-pill group mt-6 inline-flex items-center gap-3 pl-4 pr-3 py-2 rounded-full glass border-cyan-400/30 hover:border-cyan-300/60 hover:bg-white/[0.08] transition-all"
        :title="copied ? 'Скопійовано' : 'Натисни, щоб скопіювати нік'"
        :aria-label="copied ? 'Нік скопійовано' : `Скопіювати нік ${nick}`"
        @click="copyNick"
      >
        <span class="text-[10px] uppercase tracking-widest text-cyan-300/70">
          Нік для пошти
        </span>
        <span class="font-mono font-semibold text-cyan-100 text-base select-all">
          {{ nick }}
        </span>
        <span
          class="inline-flex items-center justify-center h-7 w-7 rounded-full bg-white/5 border border-white/10 group-hover:bg-cyan-400/15 group-hover:border-cyan-300/40 transition-colors"
        >
          <Transition
            mode="out-in"
            enter-active-class="transition duration-150 ease-out"
            enter-from-class="opacity-0 scale-75"
            enter-to-class="opacity-100 scale-100"
            leave-active-class="transition duration-100 ease-in"
            leave-from-class="opacity-100 scale-100"
            leave-to-class="opacity-0 scale-75"
          >
            <svg
              v-if="!copied"
              key="copy"
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="text-slate-300 group-hover:text-cyan-200"
              aria-hidden="true"
            >
              <rect
                x="9"
                y="9"
                width="13"
                height="13"
                rx="2"
                ry="2"
              />
              <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
            </svg>
            <svg
              v-else
              key="check"
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.5"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="text-emerald-300"
              aria-hidden="true"
            >
              <polyline points="20 6 9 17 4 12" />
            </svg>
          </Transition>
        </span>
      </button>

      <Transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="opacity-0 -translate-y-1"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <span
          v-if="copied"
          class="mt-2 text-xs text-emerald-300"
          role="status"
          aria-live="polite"
        >
          Скопійовано в буфер обміну
        </span>
      </Transition>
    </div>
  </section>
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

.nick-pill {
  cursor: copy;
  box-shadow: 0 0 0 0 rgba(56, 189, 248, 0);
  transition: box-shadow 200ms ease, border-color 200ms ease, background-color 200ms ease;
}
.nick-pill:hover {
  box-shadow: 0 0 18px rgba(56, 189, 248, 0.35);
}
.nick-pill:active {
  transform: translateY(1px);
}
</style>
