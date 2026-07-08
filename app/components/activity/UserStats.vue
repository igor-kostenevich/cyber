<script setup lang="ts">
interface Props {
  balance: number
  rank?: number | null
  monthPoints?: number
  eventsCount?: number
  nickname?: string | null
}

const props = withDefaults(defineProps<Props>(), {
  rank: null,
  monthPoints: 0,
  eventsCount: 0,
  nickname: null,
})

const rankLabel = computed(() => (props.rank ? `#${props.rank}` : '—'))
const { formatPoints } = useFormatPoints()
</script>

<template>
  <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
    <GlowCard class="text-center">
      <div class="text-xs uppercase tracking-widest text-cyan-300/70 flex items-center justify-center gap-1">
        <CyberPointIcon size="xs" />
        <span>Баланс CR</span>
      </div>
      <div class="mt-1 font-display text-3xl neon-text flex items-center justify-center gap-2">
        <CyberPointIcon size="lg" />
        <span>{{ formatPoints(balance) }}</span>
      </div>
    </GlowCard>

    <GlowCard
      tone="violet"
      class="text-center"
    >
      <div class="text-xs uppercase tracking-widest text-violet-300/70">
        Місце в рейтингу
      </div>
      <div class="mt-1 font-display text-3xl neon-text-violet">
        {{ rankLabel }}
      </div>
    </GlowCard>

    <GlowCard class="text-center">
      <div class="text-xs uppercase tracking-widest text-cyan-300/70 flex items-center justify-center gap-1">
        <CyberPointIcon size="xs" />
        <span>CR за місяць</span>
      </div>
      <div class="mt-1 font-display text-3xl text-cyan-100 flex items-center justify-center gap-2">
        <CyberPointIcon size="lg" />
        <span>{{ formatPoints(monthPoints) }}</span>
      </div>
    </GlowCard>

    <GlowCard
      tone="pink"
      class="text-center"
    >
      <div class="text-xs uppercase tracking-widest text-pink-300/70">
        Відвідано івентів
      </div>
      <div class="mt-1 font-display text-3xl neon-text-pink">
        {{ eventsCount }}
      </div>
    </GlowCard>
  </div>
</template>
