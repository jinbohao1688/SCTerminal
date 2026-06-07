import { OutputLine } from '../capabilities/types'

const MAX_LINES = 500
const MAX_HISTORY = 100

@ObservedV2
export class TerminalStore {
  @Trace lines: OutputLine[] = []
  @Trace sessions: string[] = ['default']
  @Trace activeSession: string = 'default'
  @Trace inputHistory: string[] = []
  @Trace currentInput: string = ''
  @Trace isProcessing: boolean = false
  @Trace currentPath: string = '~'

  appendLines(newLines: OutputLine[]): void {
    this.lines = [...this.lines, ...newLines]
    if (this.lines.length > MAX_LINES) {
      this.lines = this.lines.slice(this.lines.length - MAX_LINES)
    }
    this.isProcessing = false
  }

  appendInput(cmd: string): void {
    if (cmd.trim().length === 0) return
    if (this.inputHistory[this.inputHistory.length - 1] === cmd) return
    this.inputHistory = [...this.inputHistory, cmd]
    if (this.inputHistory.length > MAX_HISTORY) {
      this.inputHistory = this.inputHistory.slice(this.inputHistory.length - MAX_HISTORY)
    }
  }

  clearLines(): void {
    this.lines = []
  }

  setPath(path: string): void {
    this.currentPath = path
  }
}

export const terminalStore: TerminalStore = new TerminalStore()
