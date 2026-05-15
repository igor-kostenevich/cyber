export function useModal<TPayload = void>() {
  const isOpen = ref(false)
  const payload = ref<TPayload | null>(null)

  function open(value?: TPayload) {
    payload.value = (value ?? null) as TPayload | null
    isOpen.value = true
  }

  function close() {
    isOpen.value = false
    payload.value = null
  }

  function toggle(value?: TPayload) {
    if (isOpen.value) close()
    else open(value)
  }

  return {
    isOpen,
    payload,
    open,
    close,
    toggle,
  }
}
