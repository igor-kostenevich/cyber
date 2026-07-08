<script setup lang="ts">
useHead({ title: 'Вхід · Cyberpunk' })

const auth = useAuthStore()
const profile = useProfileStore()
const router = useRouter()
const route = useRoute()
const { resolveLogin } = useNicknameEmail()

const form = reactive({
  login: '',
  password: '',
})
const submitting = ref(false)
const error = ref<string | null>(null)

const destinationAfterLogin = (): string => {
  const redirect = route.query.redirect as string | undefined
  if (redirect) return redirect
  if (profile.isAdmin) return '/manage'
  if (profile.isApproved) return '/dashboard'
  return '/pending'
}

onMounted(async () => {
  await auth.init()
  if (auth.isAuthenticated) {
    await router.replace(destinationAfterLogin())
  }
})

const onSubmit = async () => {
  if (!form.login || !form.password) {
    error.value = 'Введіть нік (або email) та пароль'
    return
  }
  submitting.value = true
  error.value = null
  try {
    await auth.login(resolveLogin(form.login), form.password)
    await profile.fetchMine()
    await router.replace(destinationAfterLogin())
  }
  catch (e) {
    error.value = e instanceof Error ? e.message : 'Помилка входу'
  }
  finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="container-page min-h-[80vh] flex items-center justify-center py-12">
    <GlowCard class="w-full max-w-md space-y-5">
      <div class="text-center space-y-1">
        <div class="text-xs uppercase tracking-widest text-cyan-300/80">
          Система активності клану
        </div>
        <h1 class="font-display text-2xl text-gradient-cyber">
          Вхід
        </h1>
        <p class="text-sm text-slate-400">
          Увійдіть за своїм ігровим ніком.
        </p>
      </div>

      <form
        class="space-y-4"
        @submit.prevent="onSubmit"
      >
        <div>
          <label class="label">Нік у грі</label>
          <input
            v-model="form.login"
            type="text"
            class="input"
            autocomplete="username"
            placeholder="Ваш ігровий нік"
            required
          >
        </div>
        <div>
          <label class="label">Пароль</label>
          <input
            v-model="form.password"
            type="password"
            class="input"
            autocomplete="current-password"
            required
          >
        </div>

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
          Увійти
        </BaseButton>
      </form>

      <p class="text-center text-sm text-slate-400">
        Ще немає акаунта?
        <NuxtLink
          to="/register"
          class="text-cyan-300 hover:text-cyan-200 transition-colors"
        >
          Зареєструватися
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
