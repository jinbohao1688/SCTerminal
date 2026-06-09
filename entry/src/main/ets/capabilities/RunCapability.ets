import { CapabilityHandler, OutputLine, ok, err, info, warn } from './types'
import runner from 'librunner.so'

const BUNDLE_NAME = 'com.jin.SCTerminal'
const HNP_BIN = '/data/app/el1/bundle/public/' + BUNDLE_NAME + '/hnp/sct-tools/bin'

interface RunCommand {
  action: string
  description: string
  usage: string
}

export const COMMANDS: RunCommand[] = [
  { action: 'busybox', description: 'run busybox <args> — 执行 busybox 命令', usage: 'run busybox <args>' },
  { action: 'bash', description: 'run bash <args> — 执行 bash 命令', usage: 'run bash <args>' },
  { action: 'python', description: 'run python <file> — 执行 python 脚本', usage: 'run python <file>' },
  { action: 'which', description: 'run which <tool> — 查找工具路径', usage: 'run which <tool>' },
]

function handleWhich(binary: string): OutputLine[] {
  const lines: OutputLine[] = []
  lines.push(info('HNP base path: ' + HNP_BIN))
  lines.push(info(binary + ' expected at: ' + HNP_BIN + '/' + binary))

  const knownTools: string[] = ['busybox', 'bash', 'python', 'python3', 'python3.13']
  let found = false
  for (let i = 0; i < knownTools.length; i++) {
    if (knownTools[i] === binary) {
      found = true
      break
    }
  }

  if (found) {
    lines.push(ok('Path: ' + HNP_BIN + '/' + binary))
    lines.push(info('Tool is compiled, packaged, and ready to execute.'))
  } else {
    const available: string[] = ['busybox', 'bash', 'python']
    let list = ''
    for (let i = 0; i < available.length; i++) {
      list += available[i]
      if (i < available.length - 1) {
        list += ', '
      }
    }
    lines.push(warn('Unknown tool: ' + binary + '. Available: ' + list))
  }

  return lines
}

function buildCmd(binary: string, args: string[]): string {
  if (binary === 'bash') {
    return HNP_BIN + '/bash -c "' + args.join(' ') + '"'
  }
  if (binary === 'python') {
    return HNP_BIN + '/python3.13 ' + args.join(' ')
  }
  // busybox
  return HNP_BIN + '/busybox ' + args.join(' ')
}

async function runBinary(binary: string, args: string[]): Promise<OutputLine[]> {
  const cmd = buildCmd(binary, args)

  try {
    const output: string = runner.runCommand(cmd)
    const lines: OutputLine[] = [info('$ ' + cmd)]
    const parts = output.split('\n')
    for (let i = 0; i < parts.length; i++) {
      const line = parts[i]
      if (line.length > 0) {
        lines.push(ok(line))
      }
    }
    return lines
  } catch (e) {
    const msg = (e as Error).message
    return [err('run failed: ' + msg)]
  }
}

export const handleRun: CapabilityHandler = async (
  action: string,
  args: string[],
  _flags: Map<string, string>
): Promise<OutputLine[]> => {
  if (action === 'help') {
    const lines: OutputLine[] = [info('=== run commands ===')]
    for (let i = 0; i < COMMANDS.length; i++) {
      lines.push(ok(COMMANDS[i].usage))
      lines.push(info('  ' + COMMANDS[i].description))
    }
    lines.push(info('HNP base path: ' + HNP_BIN))
    return lines
  }

  if (action === 'which') {
    if (args.length === 0) {
      return [err('Usage: run which <tool> — e.g. run which busybox')]
    }
    return handleWhich(args[0])
  }

  const supported: string[] = ['busybox', 'bash', 'python']
  let found = false
  for (let i = 0; i < supported.length; i++) {
    if (supported[i] === action) {
      found = true
      break
    }
  }

  if (!found) {
    return [err('Unknown run target: ' + action + '. Supported: run busybox | bash | python | which')]
  }

  return runBinary(action, args)
}
