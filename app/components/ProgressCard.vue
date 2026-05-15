<script setup lang="ts">
const { summary, isLoading } = useProgress()

const percentLabel = computed(() => `${summary.value.percent.toFixed(1)}%`)
const widthStyle = computed(() => ({ width: `${summary.value.percent}%` }))
const markerStyle = computed(() => ({ left: `${summary.value.percent}%` }))
</script>

<template>
  <GlowCard class="space-y-5">
    <div class="flex items-start justify-between gap-4 flex-wrap">
      <div class="min-w-0 flex-1">
        <div class="text-xs uppercase tracking-widest text-cyan-300/80">
          Прогрес клану
        </div>

        <div
          v-if="isLoading"
          class="mt-2 flex items-center gap-3"
        >
          <SkeletonLine
            width="6rem"
            height="2rem"
            rounded="rounded-lg"
          />
          <SkeletonLine
            width="4.5rem"
            height="1.25rem"
            rounded="rounded-md"
          />
        </div>
        <div
          v-else
          class="mt-1 font-display text-2xl md:text-3xl font-bold"
        >
          <span class="text-gradient-cyber">{{ summary.collected }}</span>
          <span class="text-slate-500"> / {{ summary.target }}</span>
          <span class="ml-2 text-slate-400 text-base font-medium">печаток</span>
        </div>
      </div>

      <div class="text-right">
        <div v-if="isLoading">
          <SkeletonLine
            width="5rem"
            height="2.25rem"
            rounded="rounded-lg"
          />
          <div class="text-xs text-slate-400 mt-1">
            зібрано
          </div>
        </div>
        <div v-else>
          <div class="font-display text-3xl md:text-4xl font-black neon-text">
            {{ percentLabel }}
          </div>
          <div class="text-xs text-slate-400 mt-0.5">
            зібрано
          </div>
        </div>
      </div>
    </div>

    <div class="relative h-12 my-1">
      <div class="absolute inset-x-0 top-1/2 -translate-y-1/2 h-3 rounded-full bg-ink-700/80 overflow-hidden border border-white/5">
        <template v-if="isLoading">
          <div class="absolute inset-0 animate-pulse bg-white/[0.06]" />
        </template>
        <template v-else>
          <div
            class="absolute inset-y-0 left-0 rounded-full bg-gradient-to-r from-cyan-400 via-sky-400 to-violet-500 transition-all duration-700 ease-out"
            :style="widthStyle"
          />
          <div
            class="absolute inset-y-0 left-0 rounded-full opacity-60 blur-sm bg-gradient-to-r from-cyan-400 via-sky-400 to-violet-500 transition-all duration-700"
            :style="widthStyle"
          />
        </template>
      </div>

      <div
        v-if="!isLoading"
        class="progress-marker absolute top-1/2 h-10 w-10 -translate-x-1/2 -translate-y-1/2 rounded-full bg-ink-900/80 border border-amber-300/50 grid place-items-center transition-all duration-700 ease-out pointer-events-none"
        :style="markerStyle"
        aria-hidden="true"
      >
        <img
          src="/item1.png"
          alt=""
          class="h-7 w-7 object-contain drop-shadow-[0_0_4px_rgba(251,191,36,0.6)]"
          loading="eager"
          decoding="async"
        >
      </div>
    </div>

    <div class="grid grid-cols-3 gap-3 md:gap-4 pt-2">
      <div class="text-center p-3 rounded-xl bg-white/[0.03] border border-white/5">
        <div class="text-[10px] uppercase tracking-widest text-slate-400">
          Залишилось
        </div>
        <div class="mt-1 flex justify-center">
          <SkeletonLine
            v-if="isLoading"
            width="3rem"
            height="1.5rem"
            rounded="rounded-md"
          />
          <span
            v-else
            class="font-display text-xl md:text-2xl font-bold text-cyan-200"
          >
            {{ summary.remaining }}
          </span>
        </div>
      </div>

      <div class="text-center p-3 rounded-xl bg-white/[0.03] border border-white/5">
        <div class="text-[10px] uppercase tracking-widest text-slate-400">
          Учасників
        </div>
        <div class="mt-1 flex justify-center">
          <SkeletonLine
            v-if="isLoading"
            width="2rem"
            height="1.5rem"
            rounded="rounded-md"
          />
          <span
            v-else
            class="font-display text-xl md:text-2xl font-bold text-violet-200"
          >
            {{ summary.approvedCount }}
          </span>
        </div>
      </div>

      <div class="text-center p-3 rounded-xl bg-white/[0.03] border border-white/5">
        <div class="text-[10px] uppercase tracking-widest text-slate-400">
          З боргами
        </div>
        <div class="mt-1 flex justify-center">
          <SkeletonLine
            v-if="isLoading"
            width="2rem"
            height="1.5rem"
            rounded="rounded-md"
          />
          <span
            v-else
            class="font-display text-xl md:text-2xl font-bold"
            :class="summary.withDebtCount > 0 ? 'text-amber-200' : 'text-emerald-200'"
          >
            {{ summary.withDebtCount }}
          </span>
        </div>
      </div>
    </div>
  </GlowCard>
</template>

<style scoped>
.progress-marker {
  box-shadow:
    0 0 0 1px rgba(251, 191, 36, 0.25),
    0 0 18px rgba(251, 191, 36, 0.45),
    0 0 32px rgba(251, 191, 36, 0.25);
  animation: marker-pulse 2.4s ease-in-out infinite;
}

@keyframes marker-pulse {
  0%,
  100% {
    box-shadow:
      0 0 0 1px rgba(251, 191, 36, 0.25),
      0 0 18px rgba(251, 191, 36, 0.45),
      0 0 32px rgba(251, 191, 36, 0.25);
  }
  50% {
    box-shadow:
      0 0 0 1px rgba(251, 191, 36, 0.4),
      0 0 24px rgba(251, 191, 36, 0.65),
      0 0 44px rgba(251, 191, 36, 0.35);
  }
}
</style>
