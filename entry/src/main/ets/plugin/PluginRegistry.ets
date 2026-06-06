import { SCTerminalPlugin, PluginManifest } from './PluginSDK'
import { createContext } from './PluginSandbox'

interface PluginRegistry {
  install(plugin: SCTerminalPlugin): Promise<void>
  uninstall(id: string): Promise<void>
  resolve(namespace: string): SCTerminalPlugin | null
  list(): PluginManifest[]
  get(id: string): SCTerminalPlugin | undefined
}

const plugins = new Map<string, SCTerminalPlugin>()
const namespaceIndex = new Map<string, string>()

async function doInstall(plugin: SCTerminalPlugin): Promise<void> {
  const id = plugin.manifest.id

  if (plugins.has(id)) {
    throw new Error('Plugin "' + id + '" is already installed.')
  }

  for (let i = 0; i < plugin.commands.length; i++) {
    const cmd = plugin.commands[i]
    if (namespaceIndex.has(cmd.namespace)) {
      const owner = namespaceIndex.get(cmd.namespace)
      throw new Error('Namespace "' + cmd.namespace + '" is already claimed by plugin "' + owner + '".')
    }
  }

  const ctx = createContext(plugin)

  if (plugin.onInstall !== undefined) {
    await plugin.onInstall(ctx)
  }

  plugins.set(id, plugin)
  for (let i = 0; i < plugin.commands.length; i++) {
    namespaceIndex.set(plugin.commands[i].namespace, id)
  }
}

async function doUninstall(id: string): Promise<void> {
  const plugin = plugins.get(id)
  if (plugin === undefined) {
    throw new Error('Plugin "' + id + '" is not installed.')
  }

  if (plugin.onUninstall !== undefined) {
    await plugin.onUninstall()
  }

  for (let i = 0; i < plugin.commands.length; i++) {
    namespaceIndex.delete(plugin.commands[i].namespace)
  }
  plugins.delete(id)
}

function doResolve(namespace: string): SCTerminalPlugin | null {
  const id = namespaceIndex.get(namespace)
  if (id === undefined) return null
  const p = plugins.get(id)
  if (p !== undefined) return p
  return null
}

function doList(): PluginManifest[] {
  const result: PluginManifest[] = []
  plugins.forEach((p: SCTerminalPlugin) => result.push(p.manifest))
  return result
}

function doGet(id: string): SCTerminalPlugin | undefined {
  return plugins.get(id)
}

export { doInstall as install }
export { doUninstall as uninstall }
export { doResolve as resolve }
export { doList as list }
export { doGet as get }

class PluginRegistryImpl implements PluginRegistry {
  install(plugin: SCTerminalPlugin): Promise<void> {
    return doInstall(plugin)
  }
  uninstall(id: string): Promise<void> {
    return doUninstall(id)
  }
  resolve(namespace: string): SCTerminalPlugin | null {
    return doResolve(namespace)
  }
  list(): PluginManifest[] {
    return doList()
  }
  get(id: string): SCTerminalPlugin | undefined {
    return doGet(id)
  }
}

export const pluginRegistry: PluginRegistry = new PluginRegistryImpl()
