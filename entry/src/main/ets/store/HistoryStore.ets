import preferences from '@ohos.data.preferences'
import { getAppContext } from '../utils/AppContext'

const PREF_NAME = 'sct_prefs'
const KEY_HISTORY = 'cmd_history'
const KEY_SSH_GATEWAY = 'ssh_gateway_url'
const KEY_SSH_SESSION = 'ssh_session'
const MAX_HISTORY = 100

export interface SshSession {
  host: string
  user: string
  port: number
  gatewayUrl: string
  connectedAt: number
}

function getPrefs(): Promise<preferences.Preferences> {
  return preferences.getPreferences(getAppContext(), PREF_NAME)
}

export async function loadHistory(): Promise<string[]> {
  const prefs = await getPrefs()
  const raw = await prefs.get(KEY_HISTORY, '[]') as string
  try {
    const arr: string[] = JSON.parse(raw) as string[]
    return Array.isArray(arr) ? arr : []
  } catch {
    return []
  }
}

export async function saveHistory(history: string[]): Promise<void> {
  const trimmed = history.slice(-MAX_HISTORY)
  const prefs = await getPrefs()
  await prefs.put(KEY_HISTORY, JSON.stringify(trimmed))
  await prefs.flush()
}

export async function loadSshGateway(): Promise<string> {
  const prefs = await getPrefs()
  return await prefs.get(KEY_SSH_GATEWAY, '') as string
}

export async function saveSshGateway(url: string): Promise<void> {
  const prefs = await getPrefs()
  await prefs.put(KEY_SSH_GATEWAY, url)
  await prefs.flush()
}

export async function loadSshSession(): Promise<SshSession | null> {
  const prefs = await getPrefs()
  const raw = await prefs.get(KEY_SSH_SESSION, '') as string
  if (raw.length === 0) {
    return null
  }
  try {
    const session: SshSession = JSON.parse(raw) as SshSession
    return session
  } catch {
    return null
  }
}

export async function saveSshSession(session: SshSession): Promise<void> {
  const prefs = await getPrefs()
  await prefs.put(KEY_SSH_SESSION, JSON.stringify(session))
  await prefs.flush()
}

const KEY_REGISTRY_CACHE = 'registry_cache'

export async function saveRegistryCache(data: string): Promise<void> {
  const prefs = await getPrefs()
  await prefs.put(KEY_REGISTRY_CACHE, data)
  await prefs.flush()
}

export async function loadRegistryCache(): Promise<string | null> {
  const prefs = await getPrefs()
  const raw = await prefs.get(KEY_REGISTRY_CACHE, '') as string
  if (raw.length === 0) {
    return null
  }
  return raw
}

export async function clearSshSession(): Promise<void> {
  const prefs = await getPrefs()
  await prefs.delete(KEY_SSH_SESSION)
  await prefs.flush()
}
