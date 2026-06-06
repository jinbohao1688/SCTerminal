import { ParseResult } from '../capabilities/types'

export function parse(input: string): ParseResult {
  const raw = input.trim()
  if (raw.length === 0) {
    return { namespace: 'noop', action: 'noop', args: [], flags: new Map(), raw: '' }
  }

  const tokens = raw.split(/\s+/)
  const flags = new Map<string, string>()
  const positional: string[] = []

  for (const t of tokens) {
    if (t.startsWith('--')) {
      const eq = t.indexOf('=')
      if (eq > 2) {
        flags.set(t.slice(2, eq), t.slice(eq + 1))
      } else {
        flags.set(t.slice(2), 'true')
      }
    } else {
      positional.push(t)
    }
  }

  const namespace = positional.length > 0 ? positional[0] : 'noop'
  const action = positional.length >= 2 ? positional[1] : 'help'
  const args = positional.slice(2)

  return { namespace, action, args, flags, raw }
}
