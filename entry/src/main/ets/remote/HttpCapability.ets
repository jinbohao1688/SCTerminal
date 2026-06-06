import { CapabilityHandler, ok, err, warn } from '../capabilities/types'
import http from '@ohos.net.http'

const MAX_BODY = 2 * 1024 // 2 KB

interface HttpHeader {
  'Content-Type': string
}

interface HttpRequestOptions {
  method: http.RequestMethod
  header?: HttpHeader
  extraData?: string
  connectTimeout: number
  readTimeout: number
}

interface HttpCommand {
  action: string
  description: string
}

export const COMMANDS: HttpCommand[] = [
  { action: 'get', description: 'http get <url>' },
  { action: 'post', description: 'http post <url> <body> --header=K:V' },
]

export const handleHttp: CapabilityHandler = async (action, args, flags) => {
  switch (action) {
    case 'get': {
      if (args.length === 0) {
        return [err('Usage: http get <url>')]
      }

      const req = http.createHttp()
      try {
        const getOpts: HttpRequestOptions = {
          method: http.RequestMethod.GET,
          connectTimeout: 10000,
          readTimeout: 10000,
        }
        const resp = await req.request(args[0], getOpts)

        const body = typeof resp.result === 'string'
          ? resp.result
          : JSON.stringify(resp.result)
        const head = body.length > MAX_BODY ? body.slice(0, MAX_BODY) : body

        const lines = [ok(`Status: ${resp.responseCode}`)]
        lines.push(ok(head))
        if (body.length > MAX_BODY) {
          lines.push(warn(`… truncated to 2 KB (response is ${body.length} bytes total)`))
        }
        return lines
      } catch (e) {
        const error = e as Error
        return [err('GET failed: ' + error.message)]
      } finally {
        req.destroy()
      }
    }

    case 'post': {
      if (args.length < 2) {
        return [err('Usage: http post <url> <body> [--header=K:V]')]
      }

      const url = args[0]
      const body = args.slice(1).join(' ')
      let contentType = 'application/json'

      const headerFlag = flags.get('header')
      if (headerFlag !== undefined) {
        const colon = headerFlag.indexOf(':')
        if (colon > 0 && headerFlag.slice(0, colon) === 'Content-Type') {
          contentType = headerFlag.slice(colon + 1)
        }
      }

      const headers: HttpHeader = { 'Content-Type': contentType }

      const req = http.createHttp()
      try {
        const postOpts: HttpRequestOptions = {
          method: http.RequestMethod.POST,
          header: headers,
          extraData: body,
          connectTimeout: 10000,
          readTimeout: 10000,
        }
        const resp = await req.request(url, postOpts)

        const resBody = typeof resp.result === 'string'
          ? resp.result
          : JSON.stringify(resp.result)
        const head = resBody.length > MAX_BODY ? resBody.slice(0, MAX_BODY) : resBody

        const lines = [ok(`Status: ${resp.responseCode}`)]
        lines.push(ok(head))
        if (resBody.length > MAX_BODY) {
          lines.push(warn(`… truncated to 2 KB (response is ${resBody.length} bytes total)`))
        }
        return lines
      } catch (e) {
        const error = e as Error
        return [err('POST failed: ' + error.message)]
      } finally {
        req.destroy()
      }
    }

    default:
      return [warn(`Unknown action: ${action}. Supported: get | post`)]
  }
}
