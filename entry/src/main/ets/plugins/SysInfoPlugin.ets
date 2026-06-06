import { SCTerminalPlugin, PluginManifest, PluginCommand, PluginContext } from '../plugin/PluginSDK'
import { OutputLine } from '../capabilities/types'
import deviceInfo from '@ohos.deviceInfo'
import batteryInfo from '@ohos.batteryInfo'

export class SysInfoPlugin implements SCTerminalPlugin {
  manifest: PluginManifest = {
    id: 'com.sct.sysinfo',
    name: 'SysInfo Plugin',
    version: '1.0.0',
    author: 'SCTerminal',
    description: '系统信息增强插件，展示插件 SDK 用法',
    permissions: [],
    minSCTVersion: '1.0.0'
  }

  commands: PluginCommand[] = [
    { namespace: 'sysinfo', action: 'full',    description: '完整系统报告', usage: 'sysinfo full' },
    { namespace: 'sysinfo', action: 'battery', description: '电池详细信息', usage: 'sysinfo battery' },
    { namespace: 'sysinfo', action: 'about',   description: '插件信息',     usage: 'sysinfo about' },
  ]

  async onInstall(ctx: PluginContext): Promise<void> {
    ctx.println('SysInfo Plugin 已安装', 'success')
  }

  async execute(
    action: string,
    args: string[],
    flags: Map<string, string>,
    ctx: PluginContext
  ): Promise<OutputLine[]> {
    const lines: OutputLine[] = []

    if (action === 'full') {
      ctx.println('=== 系统完整报告 ===', 'info')
      ctx.println('品牌: ' + deviceInfo.brand, 'success')
      ctx.println('型号: ' + deviceInfo.productModel, 'success')
      ctx.println('OS: ' + deviceInfo.osFullName, 'success')
      ctx.println('电量: ' + batteryInfo.batterySOC + '%', 'success')
      ctx.println('充电状态: ' + batteryInfo.chargingStatus, 'success')
    } else if (action === 'battery') {
      ctx.println('电量: ' + batteryInfo.batterySOC + '%', 'success')
      ctx.println('健康状态: ' + batteryInfo.healthStatus, 'success')
      ctx.println('温度: ' + (batteryInfo.batteryTemperature / 10).toFixed(1) + '°C', 'success')
    } else if (action === 'about') {
      ctx.println('插件: ' + this.manifest.name, 'info')
      ctx.println('版本: ' + this.manifest.version, 'info')
      ctx.println('作者: ' + this.manifest.author, 'info')
      ctx.println('说明: ' + this.manifest.description, 'info')
    } else {
      ctx.println('未知操作: ' + action + '，支持: full | battery | about', 'warn')
    }

    return lines
  }
}

export const sysInfoPlugin = new SysInfoPlugin()
