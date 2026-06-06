import { OutputLine, OutputLineType } from '../capabilities/types'

export interface PluginManifest {
  id: string
  name: string
  version: string
  author: string
  description: string
  permissions: string[]
  minSCTVersion: string
}

export interface PluginCommand {
  namespace: string
  action: string
  description: string
  usage: string
}

export interface PluginStorage {
  get(key: string): Promise<string | null>
  set(key: string, value: string): Promise<void>
  delete(key: string): Promise<void>
}

export interface PluginContext {
  println(text: string, type?: OutputLineType): void
  readFile(path: string): Promise<string>
  writeFile(path: string, content: string): Promise<void>
  fetch(url: string): Promise<string>
  requestPermission(permissions: string[]): Promise<boolean>
  storage: PluginStorage
}

export interface SCTerminalPlugin {
  manifest: PluginManifest
  commands: PluginCommand[]

  onInstall?(ctx: PluginContext): Promise<void>
  onUninstall?(): Promise<void>

  execute(
    action: string,
    args: string[],
    flags: Map<string, string>,
    ctx: PluginContext
  ): Promise<OutputLine[]>
}
