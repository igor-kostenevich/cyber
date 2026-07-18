export interface Profession {
  id: number
  name: string
  icon: string
}

export const PROFESSIONS: Profession[] = [
  { id: 1, name: 'Воїн', icon: '/avatars/1_big.webp' },
  { id: 2, name: 'Маг', icon: '/avatars/2_big.webp' },
  { id: 3, name: 'Перевертень', icon: '/avatars/3_big.webp' },
  { id: 4, name: 'Друїд', icon: '/avatars/4_big.webp' },
  { id: 5, name: 'Лучник', icon: '/avatars/5_big.webp' },
  { id: 6, name: 'Жрець', icon: '/avatars/6_big.webp' },
  { id: 7, name: 'Асасін', icon: '/avatars/7_big.webp' },
  { id: 8, name: 'Шаман', icon: '/avatars/8_big.webp' },
  { id: 9, name: 'Страж', icon: '/avatars/9_big.webp' },
  { id: 10, name: 'Містік', icon: '/avatars/10_big.webp' },
]

export function getProfession(id: number | null | undefined): Profession | null {
  if (!id) return null
  return PROFESSIONS.find((p) => p.id === id) ?? null
}

export function useProfessions() {
  return { professions: PROFESSIONS, getProfession }
}
