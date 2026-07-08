<script setup lang="ts">
useHead({ title: 'Реєстрація · Cyberpunk' })

const auth = useAuthStore()
const profile = useProfileStore()
const router = useRouter()
const { getMessage } = useSupabaseErrorMessage()

const form = reactive({
  nickname: '',
  password: '',
  passwordConfirm: '',
  display_name: '',
  comment: '',
})
const twinNicks = ref<string[]>([])
const submitting = ref(false)
const error = ref<string | null>(null)

onMounted(async () => {
  await auth.init()
  if (auth.isAuthenticated) {
    await router.replace(profile.isApproved ? '/dashboard' : '/pending')
  }
})

const onSubmit = async () => {
  error.value = null
  if (!form.nickname.trim()) {
    error.value = 'Введіть ігровий нік'
    return
  }
  if (form.password.length < 6) {
    error.value = 'Пароль має містити щонайменше 6 символів'
    return
  }
  if (form.password !== form.passwordConfirm) {
    error.value = 'Паролі не співпадають'
    return
  }

  submitting.value = true
  try {
    await profile.register({
      nickname: form.nickname,
      password: form.password,
      display_name: form.display_name,
      comment: form.comment,
      twins: twinNicks.value,
    })
    await router.replace('/pending')
  }
  catch (e) {
    error.value = getMessage(e, 'Не вдалося зареєструватися')
  }
  finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="container-page min-h-[80vh] flex items-center justify-center py-12">
    <GlowCard class="w-full max-w-md space-y-5 animate-fade-in">
      <div class="text-center space-y-1">
        <div class="text-xs uppercase tracking-widest text-cyan-300/80">
          Система активності клану
        </div>
        <h1 class="font-display text-2xl text-gradient-cyber">
          Реєстрація
        </h1>
        <p class="text-sm text-slate-400">
          Після реєстрації акаунт очікує підтвердження адміністрацією.
        </p>
      </div>

      <form
        class="space-y-4"
        @submit.prevent="onSubmit"
      >
        <div>
          <label class="label">Нік у грі <span class="text-rose-300">*</span></label>
          <input
            v-model="form.nickname"
            type="text"
            class="input"
            autocomplete="username"
            maxlength="40"
            required
          >
        </div>
        <div>
          <label class="label">Пароль <span class="text-rose-300">*</span></label>
          <input
            v-model="form.password"
            type="password"
            class="input"
            autocomplete="new-password"
            required
          >
        </div>
        <div>
          <label class="label">Повторіть пароль <span class="text-rose-300">*</span></label>
          <input
            v-model="form.passwordConfirm"
            type="password"
            class="input"
            autocomplete="new-password"
            required
          >
        </div>
        <div>
          <label class="label">Ім'я / коментар (необов'язково)</label>
          <input
            v-model="form.display_name"
            type="text"
            class="input"
            maxlength="60"
            placeholder="Як до вас звертатися"
          >
        </div>

        <TwinsEditor v-model="twinNicks" />

        <div
          v-if="error"
          class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
        >
          {{ error }}
        </div>

        <BaseButton
          type="submit"
          :loading="submitting"
          full-width
        >
          Зареєструватися
        </BaseButton>
      </form>

      <p class="text-center text-sm text-slate-400">
        Вже маєте акаунт?
        <NuxtLink
          to="/login"
          class="text-cyan-300 hover:text-cyan-200 transition-colors"
        >
          Увійти
        </NuxtLink>
      </p>
    </GlowCard>
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
</style>
