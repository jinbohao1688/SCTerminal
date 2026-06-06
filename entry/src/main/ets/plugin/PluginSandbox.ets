import { PluginContext, PluginStorage, SCTerminalPlugin } from './PluginSDK'
import { OutputLine, OutputLineType } from '../capabilities/types'
import fs from '@ohos.file.fs'
import http from '@ohos.net.http'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import preferences from '@ohos.data.preferences'
import { getAppContext } from '../utils/AppContext'
import { Permissions } from '@ohos.privacyManager'

const PREF_SP = 'scterminal_plugin_storage'

async function getPluginPrefs(): Promise<preferences.Preferences> {
  return preferences.getPreferences(getAppContext(), PREF_SP)
}

class PluginStorageImpl implements PluginStorage {
  private prefix: string

  constructor(pluginId: string) {
    this.prefix = 'plugin.' + pluginId + '.'
  }

  async get(key: string): Promise<string | null> {
    const prefs = await getPluginPrefs()
    const val = await prefs.get(this.prefix + key, '') as string
    return val.length > 0 ? val : null
  }

  async set(key: string, value: string): Promise<void> {
    const prefs = await getPluginPrefs()
    await prefs.put(this.prefix + key, value)
    await prefs.flush()
  }

  async delete(key: string): Promise<void> {
    const prefs = await getPluginPrefs()
    await prefs.delete(this.prefix + key)
    await prefs.flush()
  }
}

class PluginContextImpl implements PluginContext {
  private plugin: SCTerminalPlugin
  private _lines: OutputLine[] = []
  storage: PluginStorage

  constructor(plugin: SCTerminalPlugin) {
    this.plugin = plugin
    this.storage = new PluginStorageImpl(plugin.manifest.id)
  }

  println(text: string, type?: OutputLineType): void {
    const t: OutputLineType = type !== undefined ? type : 'info'
    const line: OutputLine = {
      id: String(Date.now()) + String(Math.random()),
      type: t,
      text: text,
      timestamp: Date.now()
    }
    this._lines.push(line)
  }

  getLines(): OutputLine[] {
    return this._lines
  }

  async readFile(relPath: string): Promise<string> {
    const full = getAppContext().filesDir + '/' + relPath
    return fs.readTextSync(full)
  }

  async writeFile(relPath: string, content: string): Promise<void> {
    const full = getAppContext().filesDir + '/' + relPath
    const file = fs.openSync(full, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC)
    fs.writeSync(file.fd, content)
    fs.closeSync(file)
  }

  async fetch(url: string): Promise<string> {
    if (url.indexOf('https://') !== 0) {
      throw new Error('Plugin sandbox: only https URLs are allowed. Got: ' + url)
    }
    const req = http.createHttp()
    try {
      const resp = await req.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 30000,
      })
      return typeof resp.result === 'string' ? resp.result : JSON.stringify(resp.result)
    } finally {
      req.destroy()
    }
  }

  async requestPermission(permissions: string[]): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      const perms: Permissions[] = permissions as Permissions[]
      const result = await atManager.requestPermissionsFromUser(getAppContext(), perms)
      return result.authResults.every((r: number) => r === 0)
    } catch {
      return false
    }
  }
}

export function createContext(plugin: SCTerminalPlugin): PluginContextImpl {
  return new PluginContextImpl(plugin)
}
