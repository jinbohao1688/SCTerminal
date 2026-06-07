import http from '@ohos.net.http'
import fs from '@ohos.file.fs'
import { OutputLine, ok, err, warn, info } from '../capabilities/types'
import { pluginRegistry } from './PluginRegistry'
import { sysInfoPlugin } from '../plugins/SysInfoPlugin'
import { parseManifest } from './PluginManifest'
import { SCTerminalPlugin, PluginManifest, PluginCommand, PluginContext } from './PluginSDK'
import { getAppContext } from '../utils/AppContext'
import { loadRegistryCache, saveRegistryCache } from '../store/HistoryStore'

interface RegistryPlugin {
  id: string
  name: string
  version: string
  author: string
  description: string
  downloadUrl: string
  bundled: boolean
}

interface PluginRegistryResponse {
  version: string
  updated: string
  plugins: RegistryPlugin[]
}

interface SctPackage {
  manifest: PluginManifest
  code: string
}



const REGISTRY_URL =
  'https://raw.githubusercontent.com/jinbohao1688/SCTerminal/main/plugin-registry/registry.json'

const FALLBACK_REGISTRY: RegistryPlugin[] = [
  {
    id: 'com.sct.sysinfo',
    name: 'SysInfo Plugin',
    version: '1.0.0',
    author: 'SCTerminal',
    description: '系统信息增强插件',
    downloadUrl: '',
    bundled: true
  },
  {
    id: 'com.sct.httptest',
    name: 'HTTP Tester',
    version: '1.0.0',
    author: 'community',
    description: 'API 接口测试工具',
    downloadUrl: '',
    bundled: false
  }
]

let _registryFromFallback = false

export function isRegistryFromFallback(): boolean {
  return _registryFromFallback
}

export class ThirdPartyPluginStub implements SCTerminalPlugin {
  manifest: PluginManifest
  commands: PluginCommand[]

  constructor(manifest: PluginManifest) {
    this.manifest = manifest
    this.commands = []
  }

  async execute(
    action: string,
    args: string[],
    flags: Map<string, string>,
    ctx: PluginContext
  ): Promise<OutputLine[]> {
    ctx.println('插件 ' + this.manifest.name + ' 已安装', 'info')
    ctx.println('动态执行需要 NDK 支持，当前版本暂不可用', 'warn')
    return []
  }
}

async function fetchRegistryOnce(): Promise<RegistryPlugin[]> {
  const req = http.createHttp()
  try {
    const response = await req.request(REGISTRY_URL, {
      method: http.RequestMethod.GET,
      connectTimeout: 15000,
      readTimeout: 15000,
    })
    const body = typeof response.result === 'string'
      ? response.result
      : JSON.stringify(response.result)
    const data = JSON.parse(body) as PluginRegistryResponse
    return data.plugins
  } finally {
    req.destroy()
  }
}

export async function fetchRegistry(): Promise<RegistryPlugin[]> {
  // Try live fetch
  try {
    const plugins = await fetchRegistryOnce()
    _registryFromFallback = false
    saveRegistryCache(JSON.stringify(plugins))
    return plugins
  } catch (_e1) {
    // First attempt failed, wait 2s and retry
  }

  await new Promise<void>((resolve) => {
    setTimeout(() => { resolve() }, 2000)
  })

  try {
    const plugins = await fetchRegistryOnce()
    _registryFromFallback = false
    saveRegistryCache(JSON.stringify(plugins))
    return plugins
  } catch (_e2) {
    // Retry also failed
  }

  // Try local cache
  try {
    const cached = await loadRegistryCache()
    if (cached !== null) {
      const plugins = JSON.parse(cached) as RegistryPlugin[]
      _registryFromFallback = true
      return plugins
    }
  } catch (_e3) {
    // Cache read failed
  }

  // Fallback to built-in registry
  _registryFromFallback = true
  return FALLBACK_REGISTRY
}

export async function findPlugin(id: string): Promise<RegistryPlugin | null> {
  const plugins = await fetchRegistry()
  for (let i = 0; i < plugins.length; i++) {
    if (plugins[i].id === id) {
      return plugins[i]
    }
  }
  return null
}

export async function installPlugin(id: string): Promise<OutputLine[]> {
  const plugin = await findPlugin(id)
  if (plugin === null) {
    return [err('插件不存在: ' + id + '\n运行 plugin list --available 查看可用插件')]
  }

  if (plugin.bundled) {
    const existing = pluginRegistry.get(id)
    if (existing !== undefined) {
      return [warn(id + ' 已安装')]
    }

    if (id === 'com.sct.sysinfo') {
      await pluginRegistry.install(sysInfoPlugin)
      return [ok('已安装: ' + plugin.name + ' v' + plugin.version)]
    }

    return [err('内置插件未找到本地实例: ' + id)]
  }

  // Third-party plugin: download + install
  const lines: OutputLine[] = []
  if (plugin.downloadUrl.length === 0) {
    return [warn('该插件暂无下载地址')]
  }

  lines.push(info('正在获取插件信息...'))
  lines.push(info('正在下载 ' + plugin.name + ' v' + plugin.version + '...'))

  const req = http.createHttp()
  try {
    const response = await req.request(plugin.downloadUrl, {
      method: http.RequestMethod.GET,
      connectTimeout: 15000,
      readTimeout: 15000,
    })
    const body = typeof response.result === 'string'
      ? response.result
      : JSON.stringify(response.result)
    const data = JSON.parse(body) as SctPackage

    const manifest = parseManifest(JSON.stringify(data.manifest))

    const filesDir = getAppContext().filesDir
    const installDir = filesDir + '/sct/usr/' + id
    const dirCreated = tryMkdirSync(installDir)

    const installFile = fs.openSync(
      installDir + '/installed.json',
      fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
    )
    fs.writeSync(installFile.fd, JSON.stringify(manifest))
    fs.closeSync(installFile)

    const stub = new ThirdPartyPluginStub(manifest)
    await pluginRegistry.install(stub)

    lines.push(info('正在安装...'))
    lines.push(ok('安装成功: ' + plugin.name + ' v' + plugin.version))
    lines.push(info('注意：第三方插件执行需要 NDK 支持，命令已注册但暂不可运行'))
    return lines
  } catch (e) {
    const msg = (e as Error).message
    return [err('安装失败: ' + msg)]
  } finally {
    req.destroy()
  }
}

export async function uninstallPlugin(id: string): Promise<OutputLine[]> {
  try {
    await pluginRegistry.uninstall(id)

    const filesDir = getAppContext().filesDir
    const installFile = filesDir + '/sct/usr/' + id + '/installed.json'
    try {
      fs.unlinkSync(installFile)
    } catch (_e) {
      // File not found is OK
    }

    return [ok('已卸载: ' + id)]
  } catch (e) {
    const msg = (e as Error).message
    return [err('卸载失败: ' + msg)]
  }
}

export async function loadInstalledPlugins(): Promise<string[]> {
  const filesDir = getAppContext().filesDir
  const usrDir = filesDir + '/sct/usr'
  let dirs: string[] = []
  try {
    dirs = fs.listFileSync(usrDir)
  } catch (_e) {
    return []
  }
  const ids: string[] = []
  for (let i = 0; i < dirs.length; i++) {
    const dir = dirs[i]
    const installedPath = usrDir + '/' + dir + '/installed.json'
    try {
      fs.statSync(installedPath)
      ids.push(dir)
    } catch (_e) {
      // No installed.json in this dir, skip
    }
  }
  return ids
}

function tryMkdirSync(path: string): boolean {
  try {
    fs.mkdirSync(path)
    return true
  } catch (_e) {
    return false
  }
}
