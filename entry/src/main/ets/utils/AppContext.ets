let _ctx: Context | null = null

export function setAppContext(ctx: Context): void {
  _ctx = ctx
}

export function getAppContext(): Context {
  if (_ctx === null) {
    throw new Error('AppContext not initialized')
  }
  return _ctx
}
