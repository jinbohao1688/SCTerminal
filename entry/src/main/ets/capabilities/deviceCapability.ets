import { CapabilityHandler, ok, warn } from './types'
import deviceInfo from '@ohos.deviceInfo'

interface DeviceCommand {
  action: string
  description: string
}

export const COMMANDS: DeviceCommand[] = [
  { action: 'info', description: 'Show basic device info (brand/model/os/udid)' },
  { action: 'model', description: 'Show device type + brand + model' },
  { action: 'os', description: 'Show OS version + security patch' },
]

export const handleDevice: CapabilityHandler = async (action, _args, _flags) => {
  switch (action) {
    case 'info':
      return [
        ok(`Brand:      ${deviceInfo.brand}`),
        ok(`Model:      ${deviceInfo.marketName}`),
        ok(`OS:         ${deviceInfo.osFullName}`),
        ok(`Version:    ${deviceInfo.displayVersion}`),
        ok(`UDID (8):   ${String(deviceInfo.udid).slice(0, 8)}`),
      ]

    case 'model':
      return [
        ok(`Type:       ${deviceInfo.deviceType}`),
        ok(`Brand:      ${deviceInfo.brand}`),
        ok(`Model:      ${deviceInfo.marketName}`),
      ]

    case 'os':
      return [
        ok(`OS:            ${deviceInfo.osFullName}`),
        ok(`Security Tag:  ${deviceInfo.securityPatchTag}`),
      ]

    default:
      return [warn(`Unknown action: ${action}. Supported: info | model | os`)]
  }
}
