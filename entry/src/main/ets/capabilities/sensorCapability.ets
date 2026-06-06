import { CapabilityHandler, ok, warn, OutputLine } from './types'
import sensor from '@ohos.sensor'

interface SensorCommand {
  action: string
  description: string
}

export const COMMANDS: SensorCommand[] = [
  { action: 'list', description: 'List all available sensors' },
]

export const handleSensor: CapabilityHandler = async (action, _args, _flags): Promise<OutputLine[]> => {
  switch (action) {
    case 'list': {
      const sensors = await sensor.getSensorList()
      if (sensors.length === 0) {
        return [ok('No sensors found on this device.')]
      }

      return sensors.map((s: sensor.Sensor, i: number) =>
        ok(`${i + 1}. ${s.sensorName}  id=${s.sensorId}`)
      )
    }

    default:
      return [warn(`Unknown action: ${action}. Supported: list`)]
  }
}
