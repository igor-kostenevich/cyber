export const CYBER_POINT_SINGULAR = 'Cyber-кредит'
export const CYBER_POINT_PLURAL = 'Cyber-кредити'
export const CYBER_POINT_GENITIVE = 'Cyber-кредитів'
export const CYBER_POINT_SHORT = 'CR'

export function roundPoints(value: number): number {
  return Math.round(value * 10) / 10
}

export function parsePointsInput(raw: string | number | null | undefined): number | null {
  if (raw == null || raw === '') return null
  const text = typeof raw === 'number' ? String(raw) : String(raw).trim().replace(',', '.')
  const parsed = Number.parseFloat(text)
  if (Number.isNaN(parsed) || parsed < 0) return null
  return roundPoints(parsed)
}

export function formatPoints(value: number): string {
  const rounded = roundPoints(value)
  if (Number.isInteger(rounded)) return String(rounded)
  return rounded.toFixed(1)
}

export function cyberPointsWord(value: number): string {
  const rounded = roundPoints(value)
  if (!Number.isInteger(rounded)) return CYBER_POINT_GENITIVE

  const abs = Math.abs(rounded)
  const mod10 = abs % 10
  const mod100 = abs % 100

  if (mod10 === 1 && mod100 !== 11) return CYBER_POINT_SINGULAR
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return CYBER_POINT_PLURAL
  return CYBER_POINT_GENITIVE
}

export const pointsWord = cyberPointsWord

export function useFormatPoints() {
  return {
    roundPoints,
    parsePointsInput,
    formatPoints,
    cyberPointsWord,
    pointsWord: cyberPointsWord,
    CYBER_POINT_SINGULAR,
    CYBER_POINT_PLURAL,
    CYBER_POINT_GENITIVE,
    CYBER_POINT_SHORT,
  }
}
