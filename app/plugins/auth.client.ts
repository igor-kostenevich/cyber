export default defineNuxtPlugin(() => {
  // Ініціалізуємо сесію у фоні, щоб не блокувати монтування застосунку.
  // Middleware (auth/approved/admin) самі чекають auth.init() там, де це потрібно.
  const auth = useAuthStore()
  void auth.init()
})
