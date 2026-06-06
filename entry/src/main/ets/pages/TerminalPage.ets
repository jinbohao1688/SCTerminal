import { OutputLine, info } from '../capabilities/types'
import { parse } from '../engine/CommandParser'
import { dispatch } from '../engine/CapabilityDispatcher'
import { terminalStore } from '../store/TerminalStore'
import { loadHistory, saveHistory } from '../store/HistoryStore'
import { setAppContext } from '../utils/AppContext'
import { sysInfoPlugin } from '../plugins/SysInfoPlugin'
import { pluginRegistry } from '../plugin/PluginRegistry'
import { COLORS } from '../utils/color'
import router from '@ohos.router'
import { StatusBar } from '../components/StatusBar'
import { TabBar } from '../components/TabBar'
import { TerminalView } from '../components/TerminalView'
import { CommandInput } from '../components/CommandInput'

const WELCOME: OutputLine[] = [
  info('  SCTerminal v1.0'),
  info('  HarmonyOS Developer Command Hub'),
  info('──────────────────────────────'),
  info('  输入 help 查看所有命令'),
  info('  输入 plugin install 安装插件'),
  info('  输入 ssh connect 连接远程服务器'),
  info(''),
]

@Entry
@Component
struct TerminalPage {
  @State lines: OutputLine[] = []
  @State sessions: string[] = []
  @State activeSession: string = ''
  @State inputHistory: string[] = []
  @State isProcessing: boolean = false

  async aboutToAppear(): Promise<void> {
    setAppContext(getContext())
    await pluginRegistry.install(sysInfoPlugin)
    this.inputHistory = await loadHistory()
    terminalStore.inputHistory = this.inputHistory

    this.lines = [...WELCOME]
    terminalStore.lines = this.lines

    this.sessions = terminalStore.sessions
    this.activeSession = terminalStore.activeSession
  }

  private syncFromStore(): void {
    this.lines = terminalStore.lines
    this.sessions = terminalStore.sessions
    this.activeSession = terminalStore.activeSession
    this.inputHistory = terminalStore.inputHistory
    this.isProcessing = terminalStore.isProcessing
  }

  async onSubmit(cmd: string): Promise<void> {
    if (cmd.length === 0) return

    const echo: OutputLine = {
      id: String(Date.now() + Math.random()),
      type: 'cmd',
      text: cmd,
      timestamp: Date.now(),
    }

    // Handle built-in clear before parse/dispatch
    if (cmd === 'clear') {
      terminalStore.appendInput(cmd)
      terminalStore.clearLines()
      this.syncFromStore()
      await saveHistory(terminalStore.inputHistory)
      return
    }

    // Handle built-in history
    if (cmd === 'history') {
      terminalStore.appendInput(cmd)
      terminalStore.appendLines([
        echo,
        ...terminalStore.inputHistory.map((h, i) => info(`${i + 1}. ${h}`)),
      ])
      this.syncFromStore()
      await saveHistory(terminalStore.inputHistory)
      return
    }

    terminalStore.isProcessing = true
    this.isProcessing = true

    const parsed = parse(cmd)
    const result = await dispatch(parsed)

    terminalStore.appendInput(cmd)
    terminalStore.appendLines([echo, ...result])
    this.syncFromStore()
    await saveHistory(terminalStore.inputHistory)
  }

  build() {
    Column() {
      StatusBar()
      TabBar({
        sessions: this.sessions,
        activeSession: this.activeSession,
        onSwitch: (id: string) => {
          terminalStore.activeSession = id
          this.activeSession = id
        },
        onClose: (id: string) => {
          if (terminalStore.sessions.length <= 1) return
          terminalStore.sessions = terminalStore.sessions.filter(s => s !== id)
          if (terminalStore.activeSession === id) {
            terminalStore.activeSession = terminalStore.sessions[0]
          }
          this.syncFromStore()
        },
      })

      Row() {
        Blank()
        Button('插件')
          .fontSize(11)
          .fontColor(COLORS.INFO)
          .backgroundColor('#1A1A1A')
          .borderRadius(4)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .margin({ right: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/PluginManagerPage' })
          })
      }
      .width('100%')

      TerminalView({ lines: this.lines })
      CommandInput({
        inputHistory: this.inputHistory,
        onSubmit: (cmd: string) => { this.onSubmit(cmd) },
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG)
  }
}
