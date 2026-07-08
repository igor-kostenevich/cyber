export function useClientMounted() {
  const mounted = ref(false)
  onMounted(() => {
    mounted.value = true
  })
  return mounted
}
