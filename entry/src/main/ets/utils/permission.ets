import { OutputLine, err } from '../capabilities/types'
import { atomiAbilityAccessCtrl } from '@ohos.abilityAccessCtrl'

export async function requestPermission(ctx: Context, permissions: string[]): Promise<boolean> {
  try {
    const atManager = atomiAbilityAccessCtrl.createAtManager()
    const results = await atManager.requestPermissionsFromUser(ctx, permissions)
    return results.every(r => r === 0)
  } catch {
    return false
  }
}

export function makePermissionError(permission: string): OutputLine {
  return err(`Permission denied: ${permission}`)
}
