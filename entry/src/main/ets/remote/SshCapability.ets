import { CapabilityHandler, ok, err, info, warn, OutputLine } from '../capabilities/types'
import http from '@ohos.net.http'
import { SshSession, loadSshGateway, saveSshGateway, loadSshSession, saveSshSession, clearSshSession } from '../store/HistoryStore'

interface SshCommand {
  action: string
  description: string
}

interface ExecResponse {
  output: string
  exitCode: number
}

export const COMMANDS: SshCommand[] = [
  { action: 'gateway', description: '设置或查看 WebSSH 网关 URL' },
  { action: 'connect', description: 'ssh connect <host> --user=<u> --port=22' },
  { action: 'exec', description: 'ssh exec <command>' },
  { action: 'disconnect', description: '断开连接' },
  { action: 'status', description: '查看当前连接状态' },
]

export const handleSsh: CapabilityHandler = async (action, args, flags) => {
  if (action === 'gateway') {
    try {
      const url = flags.get('url')
      if (url !== undefined && url.length > 0) {
        await saveSshGateway(url)
        return [ok('网关已设置: ' + url)]
      }
      const current = await loadSshGateway()
      if (current.length === 0) {
        return [info('未设置网关。用法: ssh gateway --url=http://your-server:8080')]
      }
      return [info('当前网关: ' + current)]
    } catch (e) {
      const msg = (e as Error).message
      return [err('网关操作失败: ' + msg)]
    }
  }

  if (action === 'connect') {
    if (args.length === 0) {
      return [err('Usage: ssh connect <host> --user=<u> --port=22')]
    }
    try {
      const gatewayUrl = await loadSshGateway()
      if (gatewayUrl.length === 0) {
        return [err('请先设置网关: ssh gateway --url=http://your-server:8080')]
      }
      const host = args[0]
      const user = flags.get('user')
      const userStr = user !== undefined ? user : 'root'
      const portStr = flags.get('port')
      const port = parseInt(portStr !== undefined ? portStr : '22', 10)

      const session: SshSession = {
        host: host,
        user: userStr,
        port: port,
        gatewayUrl: gatewayUrl,
        connectedAt: Date.now(),
      }
      await saveSshSession(session)
      return [ok('已连接: ' + userStr + '@' + host + ':' + port + ' via 网关')]
    } catch (e) {
      const msg = (e as Error).message
      return [err('连接失败: ' + msg)]
    }
  }

  if (action === 'exec') {
    if (args.length === 0) {
      return [err('Usage: ssh exec <command>')]
    }
    try {
      const session = await loadSshSession()
      if (session === null) {
        return [err('请先执行 ssh connect')]
      }

      const command = args.join(' ')
      const url = session.gatewayUrl + '/exec'
      const body = JSON.stringify({
        host: session.host,
        user: session.user,
        port: session.port,
        command: command,
      })

      const req = http.createHttp()
      const resp = await req.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 30000,
      })
      req.destroy()

      const raw = typeof resp.result === 'string' ? resp.result : JSON.stringify(resp.result)
      let execResp: ExecResponse
      try {
        execResp = JSON.parse(raw) as ExecResponse
      } catch {
        return [ok(raw)]
      }

      const lines: OutputLine[] = []
      if (execResp.output !== undefined && execResp.output.length > 0) {
        const outputLines = execResp.output.split('\n')
        for (let i = 0; i < outputLines.length; i++) {
          lines.push(ok(outputLines[i]))
        }
      }

      const exitCode = execResp.exitCode !== undefined ? execResp.exitCode : 0
      if (exitCode === 0) {
        lines.push(ok('exitCode: 0'))
      } else {
        lines.push(warn('exitCode: ' + exitCode))
      }

      return lines
    } catch (e) {
      const msg = (e as Error).message
      return [err('SSH exec failed: ' + msg)]
    }
  }

  if (action === 'disconnect') {
    try {
      await clearSshSession()
      return [ok('已断开连接')]
    } catch (e) {
      const msg = (e as Error).message
      return [err('断开连接失败: ' + msg)]
    }
  }

  if (action === 'status') {
    try {
      const session = await loadSshSession()
      if (session === null) {
        return [info('未连接')]
      }
      return [info('当前连接: ' + session.user + '@' + session.host + ':' + session.port)]
    } catch (e) {
      const msg = (e as Error).message
      return [err('状态查询失败: ' + msg)]
    }
  }

  return [warn('Unknown action: ' + action + '. Supported: gateway | connect | exec | disconnect | status')]
}
