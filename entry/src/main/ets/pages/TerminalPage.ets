import { OutputLine, info } from '../capabilities/types'
import { parse } from '../engine/CommandParser'
import { dispatch } from '../engine/CapabilityDispatcher'
import { terminalStore } from '../store/TerminalStore'
import { loadHistory, saveHistory } from '../store/HistoryStore'
import { setAppContext, getAppContext } from '../utils/AppContext'
import { sysInfoPlugin } from '../plugins/SysInfoPlugin'
import { pluginRegistry } from '../plugin/PluginRegistry'
import { loadInstalledPlugins, ThirdPartyPluginStub } from '../plugin/PluginInstaller'
import { PluginManifest } from '../plugin/PluginSDK'
import fs from '@ohos.file.fs'
import { COLORS } from '../utils/color'
import router from '@ohos.router'
import { StatusBar } from '../components/StatusBar'
import { TabBar } from '../components/TabBar'
import { TerminalView } from '../components/TerminalView'
import { CommandInput } from '../components/CommandInput'

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

    const installedIds = await loadInstalledPlugins()
    const filesDir = getAppContext().filesDir
    for (let i = 0; i < installedIds.length; i++) {
      const id = installedIds[i]
      try {
        const installedPath = filesDir + '/sct/usr/' + id + '/installed.json'
        const raw = fs.readTextSync(installedPath)
        const manifest = JSON.parse(raw) as PluginManifest
        const stub = new ThirdPartyPluginStub(manifest)
        await pluginRegistry.install(stub)
      } catch (_e) {
        // Skip broken plugins
      }
    }

    this.inputHistory = await loadHistory()
    terminalStore.inputHistory = this.inputHistory

    this.lines = [info('  SCTerminal v1.0'), info('  HarmonyOS Developer Command Hub'), info('  ──────────────────────────────'), info(''), info('  help          查看所有命令'), info('  plugin install <id>   安装插件'), info('  ssh connect <host>    连接远程'), info('  fs cd / ls / cat      文件操作')]
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

    if (cmd === 'clear') {
      terminalStore.appendInput(cmd)
      terminalStore.clearLines()
      this.syncFromStore()
      await saveHistory(terminalStore.inputHistory)
      return
    }

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
      StatusBar({
        onPluginClick: () => {
          router.pushUrl({ url: 'pages/PluginManagerPage' })
        }
      })

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
