import { OutputLine, OutputLineType } from './types'

// ═══════════════════════════════════════════════════════════════
// SCTerminal Plugin SDK v1.0.0
// 外部插件开发者使用本文件定义插件
// ═══════════════════════════════════════════════════════════════

// 插件清单 —— 描述插件的基本信息
export interface PluginManifest {
  id: string              // 唯一标识符，反向域名格式，如 'com.author.pluginname'
  name: string            // 插件显示名称
  version: string         // 语义化版本号，如 '1.0.0'
  author: string          // 作者名称
  description: string     // 插件功能描述
  permissions: string[]   // 插件需要的鸿蒙权限列表
  minSCTVersion: string   // 最低支持的 SCTerminal 版本
}

// 插件注册的命令 —— 一条命令对应一个 action
export interface PluginCommand {
  namespace: string       // 命令前缀，用户输入的第一个词，如 'git'
  action: string          // 子命令，如 'status'
  description: string     // 命令说明，显示在 help 里
  usage: string           // 用法示例，如 'git status'
}

// 插件独立 KV 存储 —— 数据与插件 id 绑定，不同插件隔离
export interface PluginStorage {
  get(key: string): Promise<string | null>
  set(key: string, value: string): Promise<void>
  delete(key: string): Promise<void>
}

// PluginContext —— 插件沙箱 API
// 插件只能通过 ctx 访问系统能力，不能直接 import @ohos.* 模块
export interface PluginContext {
  // 输出文本到终端
  println(text: string, type?: OutputLineType): void

  // 读取应用沙箱内的文件（相对于沙箱根目录的路径）
  readFile(path: string): Promise<string>

  // 写入应用沙箱内的文件
  writeFile(path: string, content: string): Promise<void>

  // HTTPS GET 请求（只允许 https:// URL）
  fetch(url: string): Promise<string>

  // 向用户申请鸿蒙权限，返回是否全部授权
  requestPermission(permissions: string[]): Promise<boolean>

  // 插件独立的 KV 存储
  storage: PluginStorage
}

// SCTerminalPlugin —— 插件必须实现此接口
export interface SCTerminalPlugin {
  manifest: PluginManifest            // 插件元数据
  commands: PluginCommand[]           // 插件提供的命令列表

  // 插件安装时调用，适合做初始化（创建目录、设置默认值等）
  onInstall?(ctx: PluginContext): Promise<void>

  // 插件卸载时调用，适合做清理（删除缓存、释放资源等）
  onUninstall?(): Promise<void>

  // 核心方法 —— 每次用户输入匹配到本插件时调用
  // action: 子命令名
  // args: 位置参数列表
  // flags: --key=value 标志，无值时值为 'true'
  // ctx: 沙箱上下文，通过它输出内容、访问文件、请求网络
  // 返回值: 额外的 OutputLine[]（ctx.println 的输出已自动收集，返回值会追加到其后）
  execute(
    action: string,
    args: string[],
    flags: Map<string, string>,
    ctx: PluginContext
  ): Promise<OutputLine[]>
}
