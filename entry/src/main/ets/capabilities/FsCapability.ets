import { CapabilityHandler, ok, err, warn } from './types'
import fs from '@ohos.file.fs'
import { getAppContext } from '../utils/AppContext'
import { terminalStore } from '../store/TerminalStore'

const MAX_CAT = 20 * 1024

interface FsCommand {
  action: string
  description: string
}

export const COMMANDS: FsCommand[] = [
  { action: 'ls',    description: 'fs ls [path] — 列出目录内容' },
  { action: 'cat',   description: 'fs cat <file> — 读取文件内容' },
  { action: 'write', description: 'fs write <file> <content> — 写入文件' },
  { action: 'rm',    description: 'fs rm <file> — 删除文件' },
  { action: 'mkdir', description: 'fs mkdir <dir> — 创建目录' },
  { action: 'stat',  description: 'fs stat <path> — 文件/目录信息' },
  { action: 'cp',    description: 'fs cp <src> <dst> — 复制文件' },
  { action: 'pwd',   description: 'fs pwd — 显示当前工作目录' },
  { action: 'cd',    description: 'fs cd [dir] — 切换当前目录' },
]

function getFilesDir(): string {
  return getAppContext().filesDir
}

function getHomeDir(): string {
  return getFilesDir() + '/sct/home'
}

function normalizePathComponents(input: string): string {
  const parts: string[] = []
  const segments = input.split('/')
  for (let i = 0; i < segments.length; i++) {
    const seg = segments[i]
    if (seg === '' || seg === '.') {
      continue
    }
    if (seg === '..') {
      if (parts.length > 0) {
        parts.pop()
      }
      continue
    }
    parts.push(seg)
  }
  const result = parts.join('/')
  if (input.length > 0 && input[0] === '/') {
    return '/' + result
  }
  return result
}

function currentDir(): string {
  const cwd = terminalStore.currentPath
  if (cwd.length > 0 && cwd[0] === '~') {
    return getHomeDir() + cwd.slice(1)
  }
  if (cwd.length > 0 && cwd[0] === '/') {
    return getFilesDir() + cwd
  }
  return getHomeDir()
}

function resolvePath(userPath: string): string {
  const filesDir = getFilesDir()
  let fullPath: string
  if (userPath.length > 0 && userPath[0] === '/') {
    fullPath = filesDir + userPath
  } else {
    fullPath = currentDir() + '/' + userPath
  }
  const normalized = normalizePathComponents(fullPath)
  const normalizedFilesDir = normalizePathComponents(filesDir)
  if (normalized.indexOf(normalizedFilesDir) !== 0) {
    throw new Error('路径穿越检测: 不允许访问沙箱外路径')
  }
  return normalized
}

export const handleFs: CapabilityHandler = async (action, args, _flags) => {
  switch (action) {
    case 'ls': {
      try {
        const dirPath = args.length > 0 ? resolvePath(args[0]) : resolvePath('')
        const names = fs.listFileSync(dirPath)
        if (names.length === 0) {
          return [ok('(empty)')]
        }
        return names.map((name) => ok('  ' + name))
      } catch (e) {
        const msg = (e as Error).message
        return [err('ls failed: ' + msg)]
      }
    }

    case 'cat': {
      if (args.length === 0) {
        return [err('Usage: fs cat <file>')]
      }
      try {
        const filePath = resolvePath(args[0])
        const raw = fs.readTextSync(filePath)
        if (raw.length === 0) {
          return [ok('(empty)')]
        }
        if (raw.length > MAX_CAT) {
          const head = raw.slice(0, MAX_CAT)
          return [ok(head), warn('… truncated to 20 KB (file is ' + raw.length + ' bytes total)')]
        }
        return [ok(raw)]
      } catch (e) {
        const msg = (e as Error).message
        return [err('cat failed: ' + msg)]
      }
    }

    case 'write': {
      if (args.length < 2) {
        return [err('Usage: fs write <file> <content>')]
      }
      try {
        const filePath = resolvePath(args[0])
        const content = args.slice(1).join(' ')
        const userPath = args[0]
        const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
        fs.writeSync(file.fd, content)
        fs.closeSync(file.fd)
        return [ok('Written: ' + content.length + ' bytes to ' + userPath)]
      } catch (e) {
        const msg = (e as Error).message
        return [err('write failed: ' + msg)]
      }
    }

    case 'rm': {
      if (args.length === 0) {
        return [err('Usage: fs rm <file>')]
      }
      try {
        const filePath = resolvePath(args[0])
        fs.unlinkSync(filePath)
        return [ok('Deleted: ' + args[0])]
      } catch (e) {
        const msg = (e as Error).message
        return [err('rm failed: ' + msg)]
      }
    }

    case 'mkdir': {
      if (args.length === 0) {
        return [err('Usage: fs mkdir <dir>')]
      }
      try {
        const dirPath = resolvePath(args[0])
        fs.mkdirSync(dirPath)
        return [ok('Created: ' + args[0])]
      } catch (e) {
        const msg = (e as Error).message
        return [err('mkdir failed: ' + msg)]
      }
    }

    case 'stat': {
      if (args.length === 0) {
        return [err('Usage: fs stat <path>')]
      }
      try {
        const filePath = resolvePath(args[0])
        const s = fs.statSync(filePath)
        const typeStr = s.isDirectory() ? 'directory' : 'file'
        return [
          ok('Name:  ' + args[0]),
          ok('Type:  ' + typeStr),
          ok('Size:  ' + s.size + ' bytes'),
          ok('MTime: ' + new Date(s.mtime * 1000).toLocaleString()),
        ]
      } catch (e) {
        const msg = (e as Error).message
        return [err('stat failed: ' + msg)]
      }
    }

    case 'cp': {
      if (args.length < 2) {
        return [err('Usage: fs cp <src> <dst>')]
      }
      try {
        const srcPath = resolvePath(args[0])
        const dstPath = resolvePath(args[1])
        if (srcPath === dstPath) {
          return [warn('Source and destination are the same file.')]
        }
        const content = fs.readTextSync(srcPath)
        const dstFile = fs.openSync(dstPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC)
        fs.writeSync(dstFile.fd, content)
        fs.closeSync(dstFile)
        return [ok('Copied: ' + args[0] + ' → ' + args[1])]
      } catch (e) {
        const msg = (e as Error).message
        return [err('cp failed: ' + msg)]
      }
    }

    case 'pwd': {
      return [ok(terminalStore.currentPath)]
    }

    case 'cd': {
      try {
        const homeDir = getHomeDir()
        let targetPath: string
        if (args.length === 0) {
          targetPath = homeDir
        } else {
          targetPath = resolvePath(args[0])
        }
        const s = fs.statSync(targetPath)
        if (!s.isDirectory()) {
          return [err('cd failed: ' + args[0] + ' is not a directory')]
        }
        const filesDir = getFilesDir()
        let displayPath: string
        if (targetPath.indexOf(homeDir) === 0) {
          displayPath = '~' + targetPath.slice(homeDir.length)
        } else if (targetPath.indexOf(filesDir) === 0) {
          displayPath = targetPath.slice(filesDir.length)
        } else {
          displayPath = targetPath
        }
        if (displayPath.length === 0) {
          displayPath = '/'
        }
        terminalStore.setPath(displayPath)
        return [ok('')]
      } catch (e) {
        const msg = (e as Error).message
        return [err('cd failed: ' + msg)]
      }
    }

    default:
      return [warn('Unknown action: ' + action + '. Supported: ls | cat | write | rm | mkdir | stat | cp | pwd | cd')]
  }
}
