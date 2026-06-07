import { ParseResult, OutputLine, CapabilityHandler, ok, err, info, warn } from '../capabilities/types'
import { resolve as resolvePlugin } from '../plugin/PluginRegistry'
import { installPlugin, uninstallPlugin, fetchRegistry } from '../plugin/PluginInstaller'
import { pluginRegistry } from '../plugin/PluginRegistry'
import { createContext } from '../plugin/PluginSandbox'
import { handleDevice, COMMANDS as DEVICE_COMMANDS } from '../capabilities/deviceCapability'
import { handleBattery, COMMANDS as BATTERY_COMMANDS } from '../capabilities/batteryCapability'
import { handleNetwork, COMMANDS as NET_COMMANDS } from '../capabilities/networkCapability'
import { handleSensor, COMMANDS as SENSOR_COMMANDS } from '../capabilities/sensorCapability'
import { handleFile, COMMANDS as FILE_COMMANDS } from '../capabilities/fileCapability'
import { handleFs, COMMANDS as FS_COMMANDS } from '../capabilities/FsCapability'
import { handleHmos, COMMANDS as HMOS_COMMANDS } from '../capabilities/HmosCapability'
import { handleSsh, COMMANDS as SSH_COMMANDS } from '../remote/SshCapability'
import { handleHttp, COMMANDS as HTTP_COMMANDS } from '../remote/HttpCapability'

const handlers = new Map<string, CapabilityHandler>()
handlers.set('device',  handleDevice)
handlers.set('battery', handleBattery)
handlers.set('net',     handleNetwork)
handlers.set('sensor',  handleSensor)
handlers.set('file',    handleFile)
handlers.set('fs',      handleFs)
handlers.set('hmos',    handleHmos)
handlers.set('ssh',     handleSsh)
handlers.set('http',    handleHttp)

async function handlePlugin(action: string, args: string[], flags: Map<string, string>): Promise<OutputLine[]> {
  if (action === 'install') {
    if (args.length === 0) {
      return [err('Usage: plugin install <id>')]
    }
    return installPlugin(args[0])
  }

  if (action === 'remove') {
    if (args.length === 0) {
      return [err('Usage: plugin remove <id>')]
    }
    return uninstallPlugin(args[0])
  }

  if (action === 'list') {
    const showAvailable = flags.get('available') === 'true'
    if (showAvailable) {
      try {
        const plugins = await fetchRegistry()
        const lines: OutputLine[] = [info('--- 可用插件 ---')]
        for (let i = 0; i < plugins.length; i++) {
          const p = plugins[i]
          const installed = pluginRegistry.get(p.id) !== undefined
          const tag = installed ? ' [已安装]' : ''
          lines.push(ok(p.name + ' v' + p.version + ' (' + p.id + ')' + tag))
          lines.push(info('  ' + p.description + ' — ' + p.author))
        }
        return lines
      } catch (e) {
        const msg = (e as Error).message
        return [err('获取注册表失败: ' + msg)]
      }
    }

    const installed = pluginRegistry.list()
    if (installed.length === 0) {
      return [info('没有已安装的插件。运行 plugin list --available 查看可用插件')]
    }
    const lines: OutputLine[] = [info('--- 已安装插件 ---')]
    for (let i = 0; i < installed.length; i++) {
      const m = installed[i]
      lines.push(ok(m.name + ' v' + m.version + ' (' + m.id + ')'))
      lines.push(info('  ' + m.description + ' — ' + m.author))
    }
    return lines
  }

  return [warn('Unknown action: ' + action + '. Supported: install | remove | list')]
}

handlers.set('plugin',  handlePlugin)

function buildHelp(): OutputLine[] {
  const lines: OutputLine[] = []

  lines.push(ok('  help'))
  lines.push(info('    → Show all commands'))
  lines.push(ok('  clear'))
  lines.push(info('    → Clear screen'))
  lines.push(ok('  history'))
  lines.push(info('    → Command history'))
  lines.push(ok('  plugin install/list/remove'))
  lines.push(info('    → Plugin management'))

  for (let i = 0; i < DEVICE_COMMANDS.length; i++) {
    lines.push(ok('  device ' + DEVICE_COMMANDS[i].action))
    lines.push(info('    → ' + DEVICE_COMMANDS[i].description))
  }
  for (let i = 0; i < BATTERY_COMMANDS.length; i++) {
    lines.push(ok('  battery ' + BATTERY_COMMANDS[i].action))
    lines.push(info('    → ' + BATTERY_COMMANDS[i].description))
  }
  for (let i = 0; i < NET_COMMANDS.length; i++) {
    lines.push(ok('  net ' + NET_COMMANDS[i].action))
    lines.push(info('    → ' + NET_COMMANDS[i].description))
  }
  for (let i = 0; i < SENSOR_COMMANDS.length; i++) {
    lines.push(ok('  sensor ' + SENSOR_COMMANDS[i].action))
    lines.push(info('    → ' + SENSOR_COMMANDS[i].description))
  }
  for (let i = 0; i < FILE_COMMANDS.length; i++) {
    lines.push(ok('  file ' + FILE_COMMANDS[i].action))
    lines.push(info('    → ' + FILE_COMMANDS[i].description))
  }
  for (let i = 0; i < SSH_COMMANDS.length; i++) {
    lines.push(ok('  ssh ' + SSH_COMMANDS[i].action))
    lines.push(info('    → ' + SSH_COMMANDS[i].description))
  }
  for (let i = 0; i < HTTP_COMMANDS.length; i++) {
    lines.push(ok('  http ' + HTTP_COMMANDS[i].action))
    lines.push(info('    → ' + HTTP_COMMANDS[i].description))
  }
  for (let i = 0; i < FS_COMMANDS.length; i++) {
    lines.push(ok('  ' + FS_COMMANDS[i].action))
    lines.push(info('    → ' + FS_COMMANDS[i].description))
  }
  for (let i = 0; i < HMOS_COMMANDS.length; i++) {
    lines.push(ok('  ' + HMOS_COMMANDS[i].usage))
    lines.push(info('    → ' + HMOS_COMMANDS[i].description))
  }

  return lines
}

function builtinHelp(_action: string, _args: string[], _flags: Map<string, string>): Promise<OutputLine[]> {
  return Promise.resolve(buildHelp())
}

function builtinClear(_action: string, _args: string[], _flags: Map<string, string>): Promise<OutputLine[]> {
  return Promise.resolve([])
}

function builtinHistory(_action: string, _args: string[], _flags: Map<string, string>): Promise<OutputLine[]> {
  return Promise.resolve([info('History: not yet implemented')])
}

const BUILTINS = new Map<string, CapabilityHandler>()
BUILTINS.set('help',    builtinHelp)
BUILTINS.set('clear',   builtinClear)
BUILTINS.set('history', builtinHistory)

export async function dispatch(parsed: ParseResult): Promise<OutputLine[]> {
  const namespace = parsed.namespace
  const action = parsed.action
  const args = parsed.args
  const flags = parsed.flags
  const raw = parsed.raw

  if (namespace === 'noop') {
    return []
  }

  // 1) Built-in commands
  const builtin = BUILTINS.get(namespace)
  if (builtin !== undefined) {
    try {
      const echo: OutputLine = { id: String(Date.now() + Math.random()), type: 'cmd', text: raw, timestamp: Date.now() }
      return [echo, ...(await builtin(action, args, flags))]
    } catch (e) {
      return [err(`Built-in "${namespace}" failed: ${e}`)]
    }
  }

  // 2) Registered capability/remote handlers
  const handler = handlers.get(namespace)
  if (handler !== undefined) {
    try {
      const echo: OutputLine = { id: String(Date.now() + Math.random()), type: 'cmd', text: raw, timestamp: Date.now() }
      return [echo, ...(await handler(action, args, flags))]
    } catch (e) {
      return [err(`Handler "${namespace}" failed: ${e}`)]
    }
  }

  // 3) Plugin commands
  const plugin = resolvePlugin(namespace)
  if (plugin !== null) {
    try {
      const echo: OutputLine = { id: String(Date.now() + Math.random()), type: 'cmd', text: raw, timestamp: Date.now() }
      const ctx = createContext(plugin)
      const pluginLines = await plugin.execute(action, args, flags, ctx)
      const ctxLines = ctx.getLines()
      return [echo, ...ctxLines, ...pluginLines]
    } catch (e) {
      const msg = (e as Error).message
      return [err('Plugin "' + namespace + '" failed: ' + msg)]
    }
  }

  // 4) Unknown command
  return [err(`Unknown command: ${namespace}. Type "help" to see available commands.`)]
}
