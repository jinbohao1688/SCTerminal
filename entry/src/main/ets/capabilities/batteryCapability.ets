import { CapabilityHandler, ok, warn } from './types'
import batteryInfo from '@ohos.batteryInfo'

interface BatteryCommand {
  action: string
  description: string
}

export const COMMANDS: BatteryCommand[] = [
  { action: 'status', description: 'Show battery level / charging / health / temperature' },
]

export const handleBattery: CapabilityHandler = async (action, _args, _flags) => {
  switch (action) {
    case 'status': {
      const level = batteryInfo.batterySOC >= 0 ? `${batteryInfo.batterySOC}%` : 'N/A'
      const charging = batteryInfo.chargingStatus !== undefined ? String(batteryInfo.chargingStatus) : 'N/A'
      const health = batteryInfo.healthStatus !== undefined ? String(batteryInfo.healthStatus) : 'N/A'
      const temp = batteryInfo.batteryTemperature !== undefined
        ? `${(batteryInfo.batteryTemperature / 10).toFixed(1)}°C`
        : 'N/A'

      return [
        ok(`Level:      ${level}`),
        ok(`Charging:   ${charging}`),
        ok(`Health:     ${health}`),
        ok(`Temp:       ${temp}`),
      ]
    }

    default:
      return [warn(`Unknown action: ${action}. Supported: status`)]
  }
}
