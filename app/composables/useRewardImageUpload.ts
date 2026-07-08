const BUCKET = 'reward-images'
const MAX_BYTES = 5 * 1024 * 1024
const ALLOWED = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif'])

export function useRewardImageUpload() {
  const client = useAppSupabaseClient()

  async function upload(rewardId: string, file: File): Promise<string> {
    if (!ALLOWED.has(file.type)) {
      throw new Error('Дозволені лише JPEG, PNG, WebP або GIF')
    }
    if (file.size > MAX_BYTES) {
      throw new Error('Файл занадто великий (макс. 5 МБ)')
    }

    const ext = file.name.split('.').pop()?.toLowerCase() ?? 'jpg'
    const path = `${rewardId}/${Date.now()}.${ext}`

    const { error } = await client.storage
      .from(BUCKET)
      .upload(path, file, { upsert: true, contentType: file.type })

    if (error) throw error

    const { data } = client.storage.from(BUCKET).getPublicUrl(path)
    return data.publicUrl
  }

  return { upload }
}
