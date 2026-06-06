export interface ParseResult {
  namespace: string
  action: string
  args: string[]
  flags: Map<string, string>
  raw: string
}

export type OutputLineType = 'success' | 'error' | 'info' | 'warn' | 'cmd'

export interface OutputLine {
  id: string
  type: OutputLineType
  text: string
  timestamp: number
}

export type CapabilityHandler = (
  action: string,
  args: string[],
  flags: Map<string, string>
) => Promise<OutputLine[]>

function makeLine(type: OutputLineType, text: string): OutputLine {
  return { id: String(Date.now() + Math.random()), type, text, timestamp: Date.now() }
}

export function ok(text: string): OutputLine   { return makeLine('success', text) }
export function err(text: string): OutputLine  { return makeLine('error', text) }
export function info(text: string): OutputLine { return makeLine('info', text) }
export function warn(text: string): OutputLine { return makeLine('warn', text) }
