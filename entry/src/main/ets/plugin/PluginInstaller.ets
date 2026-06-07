import http from '@ohos.net.http'
import { OutputLine, ok, err, warn, info } from '../capabilities/types'
import { pluginRegistry } from './PluginRegistry'
import { sysInfoPlugin } from '../plugins/SysInfoPlugin'

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

const REGISTRY_URL =
  'https://raw.githubusercontent.com/jinbohao1688/SCTerminal/main/plugin-registry/registry.json'

export async function fetchRegistry(): Promise<RegistryPlugin[]> {
  const req = http.createHttp()
  try {
    const response = await req.request(REGISTRY_URL, {
      method: http.RequestMethod.GET,
      connectTimeout: 10000,
      readTimeout: 10000,
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

  return [warn('第三方插件安装暂不支持，等待后续版本')]
}

export async function uninstallPlugin(id: string): Promise<OutputLine[]> {
  try {
    await pluginRegistry.uninstall(id)
    return [ok('已卸载: ' + id)]
  } catch (e) {
    const msg = (e as Error).message
    return [err('卸载失败: ' + msg)]
  }
}
