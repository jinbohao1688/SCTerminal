import { CapabilityHandler, ok, err, info, warn, OutputLine } from './types'
import bundleManager from '@ohos.bundle.bundleManager'
import hidebug from '@ohos.hidebug'
import hilog from '@ohos.hilog'
import deviceInfo from '@ohos.deviceInfo'
import batteryInfo from '@ohos.batteryInfo'
import connection from '@ohos.net.connection'

interface HmosCommand {
  namespace: string
  action: string
  description: string
  usage: string
}

export const COMMANDS: HmosCommand[] = [
  { namespace: 'hmos', action: 'bundle list',        description: '列出 SCTerminal 自身信息', usage: 'hmos bundle list' },
  { namespace: 'hmos', action: 'bundle info <name>', description: '查看应用详细信息',   usage: 'hmos bundle info <bundleName>' },
  { namespace: 'hmos', action: 'perf cpu',           description: 'CPU 性能信息',       usage: 'hmos perf cpu' },
  { namespace: 'hmos', action: 'perf mem',           description: '内存使用情况',       usage: 'hmos perf mem' },
  { namespace: 'hmos', action: 'log',                description: '日志工具',           usage: 'hmos log [--filter=tag] [--test]' },
  { namespace: 'hmos', action: 'screenshot',         description: '截图（暂不可用）',   usage: 'hmos screenshot' },
  { namespace: 'hmos', action: 'inspect <name>',     description: '检查应用权限和签名', usage: 'hmos inspect <bundleName>' },
  { namespace: 'hmos', action: 'device',             description: '设备综合状态',       usage: 'hmos device' },
]

async function handleBundleList(): Promise<OutputLine[]> {
  const selfInfo = await bundleManager.getBundleInfoForSelf(
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
  )
  const label = selfInfo.appInfo !== undefined ? selfInfo.appInfo.label : ''
  return [
    ok('SCTerminal 自身信息：'),
    ok('包名:    ' + selfInfo.name),
    ok('版本:    ' + selfInfo.versionName),
    ok('应用名:  ' + label),
  ]
}

async function handleBundleInfo(bundleName: string): Promise<OutputLine[]> {
  const bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfo(
    bundleName,
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION
  )
  const lines: OutputLine[] = [
    ok('包名:         ' + bundleInfo.name),
    ok('版本:         ' + bundleInfo.versionName),
    info('权限信息需要系统级权限，当前不可用'),
  ]
  return lines
}

async function handlePerfCpu(): Promise<OutputLine[]> {
  try {
    const cpu = hidebug.getCpuUsage()
    const heapMB = (Number(hidebug.getNativeHeapSize()) / 1024 / 1024).toFixed(2) + ' MB'
    const freeMB = (Number(hidebug.getNativeHeapFreeSize()) / 1024 / 1024).toFixed(2) + ' MB'
    return [
      ok('CPU 占用:       ' + (Number(cpu) * 100).toFixed(1) + '%'),
      ok('Native 堆大小:  ' + heapMB),
      ok('Native 堆空闲:  ' + freeMB),
    ]
  } catch (e) {
    const error = e as Error
    return [warn('性能数据获取失败: ' + error.message)]
  }
}

async function handlePerfMem(): Promise<OutputLine[]> {
  try {
    const pssKB = Number(hidebug.getPss())
    const pssMB = (pssKB / 1024).toFixed(1) + ' MB'
    const pdKB = Number(hidebug.getPrivateDirty())
    const pdMB = (pdKB / 1024).toFixed(1) + ' MB'
    const sdKB = Number(hidebug.getSharedDirty())
    const sdMB = (sdKB / 1024).toFixed(1) + ' MB'
    const heapMB = (Number(hidebug.getNativeHeapSize()) / 1024 / 1024).toFixed(1) + ' MB'
    return [
      ok('PSS 内存:       ' + pssMB),
      ok('私有脏页:       ' + pdMB),
      ok('共享脏页:       ' + sdMB),
      ok('Native 堆:      ' + heapMB),
    ]
  } catch (e) {
    const error = e as Error
    return [warn('内存数据获取失败: ' + error.message)]
  }
}

function handleLog(flags: Map<string, string>): OutputLine[] {
  const doTest = flags.get('test')
  if (doTest !== undefined) {
    hilog.info(0x0001, 'SCTerminal', 'Log test: %{public}s', 'hello')
    return [ok('已写入测试日志，请在 DevEco Studio 的 Log 窗口查看')]
  }

  const filter = flags.get('filter')
  const level = flags.get('level')
  let msg = '提示：鸿蒙 API 不支持 app 层读取系统日志流'
  msg = msg + '\n请使用 DevEco Studio → Log 窗口'
  if (filter !== undefined) {
    msg = msg + ' 过滤 tag: ' + filter
  }
  if (level !== undefined) {
    msg = msg + ' 级别: ' + level
  }
  return [info(msg)]
}

function handleScreenshot(): OutputLine[] {
  return [info('截图功能需要通过 @ohos.screenshot 的 capture() 方法\n当前 API 版本接口变更，功能暂不可用')]
}

async function handleInspect(bundleName: string): Promise<OutputLine[]> {
  const bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfo(
    bundleName,
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION
  )
  const installTime: string = bundleInfo.installTime !== undefined
    ? new Date(bundleInfo.installTime * 1000).toLocaleString()
    : 'N/A'
  const updateTime: string = bundleInfo.updateTime !== undefined
    ? new Date(bundleInfo.updateTime * 1000).toLocaleString()
    : 'N/A'
  const lines: OutputLine[] = [
    ok('包名:              ' + bundleInfo.name),
    ok('版本:              ' + bundleInfo.versionName),
    ok('版本号:            ' + String(bundleInfo.versionCode)),
    ok('安装时间:          ' + installTime),
    ok('更新时间:          ' + updateTime),
    info('权限信息需要系统级权限，当前不可用'),
  ]
  return lines
}

async function handleDevice(): Promise<OutputLine[]> {
  try {
    const net = await connection.getDefaultNet()
    const caps = await connection.getNetCapabilities(net)
    let netType = 'Unknown'
    if (caps !== undefined && caps !== null &&
        caps.bearerTypes !== undefined && caps.bearerTypes !== null &&
        caps.bearerTypes.length > 0) {
      const t = caps.bearerTypes[0]
      if (t === 0) {
        netType = 'Unknown'
      } else if (t === 1) {
        netType = 'WiFi'
      } else if (t === 2) {
        netType = 'Cellular'
      } else if (t === 3) {
        netType = 'Ethernet'
      } else {
        netType = 'Type(' + t + ')'
      }
    }

    const pssKB = Number(hidebug.getPss())
    const pssMB = (pssKB / 1024).toFixed(1) + ' MB'
    const cpu = Number(hidebug.getCpuUsage())
    const battery = batteryInfo.batterySOC >= 0 ? String(batteryInfo.batterySOC) + '%' : 'N/A'

    return [
      ok('设备型号:  ' + deviceInfo.brand + ' ' + deviceInfo.marketName),
      ok('OS 版本:   ' + deviceInfo.osFullName),
      ok('SDK 版本:  ' + deviceInfo.sdkApiVersion.toString()),
      ok(''),
      ok('内存 PSS:   ' + pssMB),
      ok('CPU 占用:   ' + (cpu * 100).toFixed(1) + '%'),
      ok('网络状态:  ' + netType),
      ok('电量:       ' + battery),
    ]
  } catch (e) {
    const error = e as Error
    return [warn('设备信息获取失败: ' + error.message)]
  }
}

export const handleHmos: CapabilityHandler = async (action, args, flags) => {
  if (action === 'bundle') {
    if (args.length === 0) {
      return [err('Usage: hmos bundle list | hmos bundle info <bundleName>')]
    }
    if (args[0] === 'list') {
      try {
        return handleBundleList()
      } catch (e) {
        const error = e as Error
        return [err('获取 bundle 信息失败: ' + error.message)]
      }
    } else if (args[0] === 'info') {
      const bundleName = args.length > 1 ? args[1] : ''
      if (bundleName.length === 0) {
        return [err('Usage: hmos bundle info <bundleName>')]
      }
      try {
        return handleBundleInfo(bundleName)
      } catch (e) {
        const error = e as Error
        return [err('获取 bundle 信息失败: ' + error.message)]
      }
    }
    return [warn('Unknown bundle action: ' + args[0] + '. Supported: list | info')]
  }

  if (action === 'perf') {
    if (args.length === 0) {
      return [err('Usage: hmos perf cpu | hmos perf mem')]
    }
    if (args[0] === 'cpu') {
      return handlePerfCpu()
    } else if (args[0] === 'mem') {
      return handlePerfMem()
    }
    return [warn('Unknown perf action: ' + args[0] + '. Supported: cpu | mem')]
  }

  if (action === 'log') {
    return handleLog(flags)
  }

  if (action === 'screenshot') {
    return handleScreenshot()
  }

  if (action === 'inspect') {
    if (args.length === 0) {
      return [err('Usage: hmos inspect <bundleName>')]
    }
    try {
      return handleInspect(args[0])
    } catch (e) {
      const error = e as Error
      return [err('检查应用失败: ' + error.message)]
    }
  }

  if (action === 'device') {
    return handleDevice()
  }

  return [warn('Unknown action: ' + action + '. Supported: bundle list | bundle info <name> | perf cpu | perf mem | log | screenshot | inspect <name> | device')]
}
