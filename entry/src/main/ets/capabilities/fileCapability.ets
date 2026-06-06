import { CapabilityHandler, ok, err, warn } from './types'
import fs from '@ohos.file.fs'
import { getAppContext } from '../utils/AppContext'

const MAX_READ = 10 * 1024 // 10 KB

function getBaseDir(): string {
  return getAppContext().filesDir
}

interface FileCommand {
  action: string
  description: string
}

export const COMMANDS: FileCommand[] = [
  { action: 'list', description: 'List files in sandbox root' },
  { action: 'stat', description: 'Show file size + mtime (stat <name>)' },
  { action: 'read', description: 'Read file content (read <name>)' },
]

export const handleFile: CapabilityHandler = async (action, args, _flags) => {
  const base = getBaseDir()

  switch (action) {
    case 'list': {
      const names = fs.listFileSync(base)
      if (names.length === 0) {
        return [ok('Sandbox root is empty.')]
      }
      return names.map((name) => ok(`  ${name}`))
    }

    case 'stat': {
      if (args.length === 0) {
        return [err('Usage: file stat <name>')]
      }
      const path = `${base}/${args[0]}`
      const s = fs.statSync(path)
      return [
        ok(`Name:  ${args[0]}`),
        ok(`Size:  ${s.size} bytes`),
        ok(`MTime: ${new Date(s.mtime * 1000).toLocaleString()}`),
      ]
    }

    case 'read': {
      if (args.length === 0) {
        return [err('Usage: file read <name>')]
      }
      const path = `${base}/${args[0]}`
      const raw = fs.readTextSync(path)
      if (raw.length === 0) {
        return [ok('(empty)')]
      }
      if (raw.length > MAX_READ) {
        const head = raw.slice(0, MAX_READ)
        return [ok(head), warn(`… truncated to 10 KB (file is ${raw.length} bytes total)`)]
      }
      return [ok(raw)]
    }

    default:
      return [warn(`Unknown action: ${action}. Supported: list | stat | read`)]
  }
}
