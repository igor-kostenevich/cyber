<script setup lang="ts">
const rewards = useRewardsStore()

const createOpen = ref(false)

onMounted(() => {
  if (!rewards.hasLoaded) void rewards.fetchAll()
})
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between gap-3">
      <p class="text-sm text-slate-400">
        Керуйте складом: назва, ціна, залишок і зображення.
      </p>
      <BaseButton @click="createOpen = true">
        + Додати нагороду
      </BaseButton>
    </div>

    <EmptyState
      v-if="rewards.error"
      tone="error"
      title="Помилка завантаження"
      :description="rewards.error"
    />

    <div
      v-else-if="rewards.isLoading && !rewards.hasLoaded"
      class="space-y-2"
    >
      <SkeletonLine
        v-for="i in 5"
        :key="i"
        height="4rem"
        rounded="rounded-xl"
      />
    </div>

    <EmptyState
      v-else-if="rewards.items.length === 0"
      title="Список нагород порожній"
      description="Додайте першу нагороду на склад."
    >
      <template #actions>
        <BaseButton @click="createOpen = true">
          + Додати нагороду
        </BaseButton>
      </template>
    </EmptyState>

    <ul
      v-else
      class="space-y-2"
    >
      <WarehouseRow
        v-for="reward in rewards.items"
        :key="reward.id"
        :reward="reward"
      />
    </ul>

    <RewardCreateModal
      v-model:open="createOpen"
    />
  </div>
</template>
