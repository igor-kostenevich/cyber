<script setup lang="ts">
import type { Profile, UserRole } from '~/types/activity'
import { PROFESSIONS } from '~/composables/useProfessions'

const players = usePlayersStore()
const twins = useTwinsStore()
const profile = useProfileStore()
const { getMessage } = useSupabaseErrorMessage()
const { label: roleLabel } = useUserRoleLabel()
const { format } = useDateFormat()

const busyId = ref<string | null>(null)
const actionError = ref<string | null>(null)

onMounted(async () => {
  if (!players.hasLoaded) await players.fetchAll()
  if (players.items.length > 0) {
    void twins.fetchForProfiles(players.items.map((p) => p.id))
  }
})

const run = async (id: string, fn: () => Promise<void>) => {
  busyId.value = id
  actionError.value = null
  try {
    await fn()
  }
  catch (e) {
    actionError.value = getMessage(e, 'Дію не виконано')
  }
  finally {
    busyId.value = null
  }
}

const approve = (p: Profile) => run(p.id, () => players.setStatus(p.id, 'approved'))
const block = (p: Profile) => run(p.id, () => players.setStatus(p.id, 'blocked'))
const onRoleChange = (p: Profile, role: UserRole) => run(p.id, () => players.setRole(p.id, role))
const onProfessionChange = (p: Profile, val: string) =>
  run(p.id, () => players.setProfession(p.id, val ? Number(val) : null))
</script>

<template>
  <div class="space-y-6">
    <div
      v-if="actionError"
      class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
    >
      {{ actionError }}
    </div>

    <EmptyState
      v-if="players.error"
      tone="error"
      title="Помилка завантаження"
      :description="players.error"
    />

    <div
      v-else-if="players.isLoading && !players.hasLoaded"
      class="space-y-2"
    >
      <SkeletonLine
        v-for="i in 4"
        :key="i"
        height="3.5rem"
        rounded="rounded-xl"
      />
    </div>

    <template v-else>
      <!-- Очікують підтвердження -->
      <section class="space-y-3">
        <h3 class="font-display text-lg text-cyan-100">
          Очікують підтвердження
          <span class="text-slate-500 text-sm">({{ players.pending.length }})</span>
        </h3>
        <EmptyState
          v-if="players.pending.length === 0"
          title="Немає нових заявок"
          description="Усі гравці опрацьовані."
        />
        <ul
          v-else
          class="space-y-2"
        >
          <li
            v-for="p in players.pending"
            :key="p.id"
            class="glass rounded-xl px-4 py-3 flex items-center justify-between gap-3 flex-wrap"
          >
            <div class="min-w-0">
              <div class="flex items-center gap-1.5 text-sm text-slate-100">
                <ProfessionIcon :profession="p.profession" size="sm" />
                <span>{{ p.nickname }}</span>
                <span
                  v-if="p.display_name"
                  class="text-xs text-slate-500"
                >({{ p.display_name }})</span>
              </div>
              <div class="text-xs text-slate-500">
                Реєстрація: {{ format(p.created_at) }}
              </div>
              <ProfileTwinsExpander
                :profile-id="p.id"
                editable
              />
            </div>
            <div class="flex items-center gap-2">
              <BaseButton
                :loading="busyId === p.id"
                @click="approve(p)"
              >
                Підтвердити
              </BaseButton>
              <BaseButton
                variant="danger"
                :disabled="busyId === p.id"
                @click="block(p)"
              >
                Відхилити
              </BaseButton>
            </div>
          </li>
        </ul>
      </section>

      <!-- Підтверджені -->
      <section class="space-y-3">
        <h3 class="font-display text-lg text-cyan-100">
          Гравці
          <span class="text-slate-500 text-sm">({{ players.approved.length }})</span>
        </h3>
        <EmptyState
          v-if="players.approved.length === 0"
          title="Немає підтверджених гравців"
        />
        <ul
          v-else
          class="space-y-2"
        >
          <li
            v-for="p in players.approved"
            :key="p.id"
            class="glass rounded-xl px-4 py-3 flex items-center justify-between gap-3 flex-wrap"
          >
            <div class="min-w-0">
              <div class="flex items-center gap-1.5 text-sm text-slate-100">
                <ProfessionIcon :profession="p.profession" size="sm" />
                <span>{{ p.nickname }}</span>
                <span class="ml-1 badge-info text-[10px] inline-flex items-center gap-1">
                  <CyberPoints
                    :value="p.points_balance"
                    icon-size="xs"
                  />
                </span>
              </div>
              <div class="text-xs text-slate-500">
                {{ roleLabel(p.role) }}
              </div>
              <ProfileTwinsExpander
                :profile-id="p.id"
                editable
              />
            </div>
            <div class="flex items-center gap-2 flex-wrap justify-end">
              <BaseSelect
                v-if="profile.isAdmin"
                :model-value="String(p.profession ?? '')"
                size="sm"
                class="w-32"
                :disabled="busyId === p.id"
                placeholder="— клас —"
                :options="PROFESSIONS.map((pr) => ({ value: String(pr.id), label: pr.name }))"
                @update:model-value="onProfessionChange(p, $event as string)"
              />
              <BaseSelect
                v-if="profile.isAdmin && p.role !== 'super_admin' && p.id !== profile.data?.id"
                :model-value="p.role === 'admin' ? 'admin' : 'user'"
                size="sm"
                class="w-28"
                :disabled="busyId === p.id"
                :options="[
                  { value: 'user', label: 'Гравець' },
                  { value: 'admin', label: 'Адмін' },
                ]"
                @update:model-value="onRoleChange(p, $event as UserRole)"
              />
              <BaseButton
                v-if="p.role !== 'super_admin'"
                variant="danger"
                :disabled="busyId === p.id"
                @click="block(p)"
              >
                Заблокувати
              </BaseButton>
            </div>
          </li>
        </ul>
      </section>

      <!-- Заблоковані -->
      <section
        v-if="players.blocked.length"
        class="space-y-3"
      >
        <h3 class="font-display text-lg text-cyan-100">
          Заблоковані
          <span class="text-slate-500 text-sm">({{ players.blocked.length }})</span>
        </h3>
        <ul class="space-y-2">
          <li
            v-for="p in players.blocked"
            :key="p.id"
            class="glass rounded-xl px-4 py-3 flex items-center justify-between gap-3 flex-wrap opacity-70"
          >
            <div class="text-sm text-slate-200">
              {{ p.nickname }}
            </div>
            <BaseButton
              variant="ghost"
              :loading="busyId === p.id"
              @click="approve(p)"
            >
              Розблокувати
            </BaseButton>
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>
