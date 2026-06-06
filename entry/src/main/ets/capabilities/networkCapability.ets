import { CapabilityHandler, ok, warn, OutputLine } from './types'
import connection from '@ohos.net.connection'

function bearerTypeLabel(t: number): string {
  switch (t) {
    case 0: return 'Unknown'
    case 1: return 'WiFi'
    case 2: return 'Cellular'
    case 3: return 'Ethernet'
    default: return `Type(${t})`
  }
}

interface NetworkCommand {
  action: string
  description: string
}

export const COMMANDS: NetworkCommand[] = [
  { action: 'status', description: 'Show whether connected + network type' },
  { action: 'info', description: 'Show all nets with bearer types' },
]

export const handleNetwork: CapabilityHandler = async (action, _args, _flags) => {
  switch (action) {
    case 'status': {
      const net = await connection.getDefaultNet()
      const caps = await connection.getNetCapabilities(net)
      let types = 'Unknown'
      if (caps !== undefined && caps !== null &&
          caps.bearerTypes !== undefined && caps.bearerTypes !== null) {
        types = caps.bearerTypes.map(bearerTypeLabel).join(', ')
      }

      return [
        ok(`Connected:  true`),
        ok(`Type:       ${types}`),
      ]
    }

    case 'info': {
      const nets = await connection.getAllNets()
      if (nets.length === 0) {
        return [ok('No active network interfaces.')]
      }

      const lines: OutputLine[] = []
      for (let i = 0; i < nets.length; i++) {
        const caps = await connection.getNetCapabilities(nets[i])
        let types = 'Unknown'
        if (caps !== undefined && caps !== null &&
            caps.bearerTypes !== undefined && caps.bearerTypes !== null) {
          types = caps.bearerTypes.map(bearerTypeLabel).join(', ')
        }
        lines.push(ok(`Net ${i}: bearerTypes = ${types}`))
      }
      return lines
    }

    default:
      return [warn(`Unknown action: ${action}. Supported: status | info`)]
  }
}
