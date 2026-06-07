import { PluginManifest } from './PluginSDK'

export function parseManifest(json: string): PluginManifest {
  const obj = JSON.parse(json) as PluginManifest

  if (obj === null || obj === undefined) {
    throw new Error('Invalid plugin.json: must be a JSON object.')
  }

  // Explicit field checks instead of dynamic index access (obj[key] unsupported in ArkTS)
  if (obj.id === undefined) {
    throw new Error('Invalid plugin.json: missing required field "id".')
  }
  if (obj.name === undefined) {
    throw new Error('Invalid plugin.json: missing required field "name".')
  }
  if (obj.version === undefined) {
    throw new Error('Invalid plugin.json: missing required field "version".')
  }
  if (obj.author === undefined) {
    throw new Error('Invalid plugin.json: missing required field "author".')
  }
  if (obj.description === undefined) {
    throw new Error('Invalid plugin.json: missing required field "description".')
  }
  if (obj.permissions === undefined) {
    throw new Error('Invalid plugin.json: missing required field "permissions".')
  }
  if (obj.minSCTVersion === undefined) {
    throw new Error('Invalid plugin.json: missing required field "minSCTVersion".')
  }

  if (typeof obj.id !== 'string' || obj.id.length === 0) {
    throw new Error('Invalid plugin.json: "id" must be a non-empty string.')
  }
  if (typeof obj.name !== 'string' || obj.name.length === 0) {
    throw new Error('Invalid plugin.json: "name" must be a non-empty string.')
  }
  if (typeof obj.version !== 'string' || obj.version.length === 0) {
    throw new Error('Invalid plugin.json: "version" must be a non-empty string.')
  }
  if (typeof obj.author !== 'string') {
    throw new Error('Invalid plugin.json: "author" must be a string.')
  }
  if (typeof obj.description !== 'string') {
    throw new Error('Invalid plugin.json: "description" must be a string.')
  }
  if (typeof obj.minSCTVersion !== 'string' || obj.minSCTVersion.length === 0) {
    throw new Error('Invalid plugin.json: "minSCTVersion" must be a non-empty string.')
  }
  if (!Array.isArray(obj.permissions)) {
    throw new Error('Invalid plugin.json: "permissions" must be a string array.')
  }
  const permArr = obj.permissions as string[]
  for (let i = 0; i < permArr.length; i++) {
    if (typeof permArr[i] !== 'string') {
      throw new Error('Invalid plugin.json: "permissions" must be a string array.')
    }
  }

  return {
    id: obj.id,
    name: obj.name,
    version: obj.version,
    author: obj.author,
    description: obj.description,
    permissions: obj.permissions,
    minSCTVersion: obj.minSCTVersion,
  }
}
