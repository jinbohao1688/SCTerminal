# SCTerminal 项目交接文档

> 给接手 AI 看的。读完这份文档你就能无缝继续开发。

---

## 项目一句话定位

**把鸿蒙设备变成开发者控制台**：本地查询系统能力，远程控制 Linux 服务器，插件扩展一切。

不是 Linux runtime，不是 Termux，不是 OS shell 模拟器。

---

## 技术栈

- 语言：ArkTS（.ets 文件，TypeScript 严格超集）
- UI：ArkUI（@Component / @Entry / @ObservedV2）
- 平台：HarmonyOS NEXT API 12+
- 构建：DevEco Studio + hvigor
- 仓库：https://github.com/jinbohao1688/SCTerminal.git

---

## ArkTS 关键限制（血泪教训，必读）

开发过程中踩过的坑，接手后不要再踩：

| 禁止 | 替代方案 |
|------|---------|
| any / unknown 类型 | 声明具体 interface |
| Object 作为类型 | 声明具体 interface |
| catch(e: Error) | catch(e) 然后内部 const err = e as Error |
| ?? 空值合并 | 三元表达式 |
| ?. 可选链 | if 守卫 |
| Array.from() | forEach + push |
| for...of Map | Map.forEach() |
| new Map([...]) | new Map() + 逐个 .set() |
| Record<K,V> | 声明具体 interface |
| T['key'] 索引访问类型 | 独立 type 别名 |
| 函数内嵌套函数 | 提升到模块级别 |
| 解构赋值 const {a} = obj | 逐属性访问 |
| as const | 普通数组/对象 |
| ReturnType<typeof fn> | 直接写返回类型 |
| 对象字面量实现含方法的接口 | class 实现 |
| getContext() | 从外部传入 UIAbilityContext |

---

## 已完成功能清单

### 命令引擎
- engine/CommandParser.ets — string 转 ParseResult
- engine/CapabilityDispatcher.ets — ParseResult 转 OutputLine[]
- 内置命令：help / clear / history

### 本地系统能力（capabilities/）
- deviceCapability.ets — device info/model/os
- batteryCapability.ets — battery status
- networkCapability.ets — net status/info
- sensorCapability.ets — sensor list
- fileCapability.ets — file list/stat/read
- HmosCapability.ets — hmos bundle/perf/log/screenshot/inspect/device

### 远程能力（remote/）
- SshCapability.ets — ssh gateway/connect/exec/status/disconnect
- HttpCapability.ets — http get/post

### 插件系统（plugin/）
- PluginSDK.ets — SCTerminalPlugin 接口定义
- PluginRegistry.ets — 注册/卸载/查找
- PluginSandbox.ets — PluginContextImpl class（沙箱隔离）
- PluginManifest.ets — plugin.json 解析校验

### 内置插件（plugins/）
- SysInfoPlugin.ets — 示例插件，已验证插件系统可运行

### UI
- TerminalPage.ets — 主终端页面
- PluginManagerPage.ets — 插件管理（已安装/可用插件双 Tab）
- TerminalView.ets — 输出列表
- CommandInput.ets — 输入栏
- StatusBar.ets — 顶部状态条
- TabBar.ets — 多会话 Tab

### Store
- TerminalStore.ets — @ObservedV2 全局状态单例
- HistoryStore.ets — 命令历史/SSH 会话持久化

---

## 命令路由核心规则

三词命令（如 hmos perf cpu）解析为：
- namespace = 'hmos'
- action = 'perf'
- args = ['cpu']

不是 action = 'perf cpu'。

所有 capability 用 action + args[0] 组合判断，例如：
  action === 'perf' && args[0] === 'cpu'
  action === 'bundle' && args[0] === 'list'

---

## 完整命令路由表

| 用户输入 | namespace | action | args |
|---------|-----------|--------|------|
| device info | device | info | [] |
| device model | device | model | [] |
| device os | device | os | [] |
| battery status | battery | status | [] |
| net status | net | status | [] |
| net info | net | info | [] |
| sensor list | sensor | list | [] |
| file list | file | list | [] |
| file stat name | file | stat | ['name'] |
| file read name | file | read | ['name'] |
| hmos bundle list | hmos | bundle | ['list'] |
| hmos bundle info pkg | hmos | bundle | ['info','pkg'] |
| hmos perf cpu | hmos | perf | ['cpu'] |
| hmos perf mem | hmos | perf | ['mem'] |
| hmos log | hmos | log | [] |
| hmos screenshot | hmos | screenshot | [] |
| hmos inspect pkg | hmos | inspect | ['pkg'] |
| hmos device | hmos | device | [] |
| ssh gateway | ssh | gateway | [] |
| ssh connect host | ssh | connect | ['host'] |
| ssh exec cmd | ssh | exec | ['cmd'] |
| ssh status | ssh | status | [] |
| ssh disconnect | ssh | disconnect | [] |
| http get url | http | get | ['url'] |
| http post url body | http | post | ['url','body'] |
| plugin install id | plugin | install | ['id'] |
| plugin remove id | plugin | remove | ['id'] |
| plugin list | plugin | list | [] |
| sysinfo full | sysinfo | full | [] |
| sysinfo battery | sysinfo | battery | [] |
| sysinfo about | sysinfo | about | [] |

---

## 核心类型定义

```typescript
// capabilities/types.ets

interface ParseResult {
  namespace: string
  action: string
  args: string[]
  flags: Map<string, string>
  raw: string
}

interface OutputLine {
  id: string
  type: 'success' | 'error' | 'info' | 'warn' | 'cmd'
  text: string
  timestamp: number
}

type CapabilityHandler = (
  action: string,
  args: string[],
  flags: Map<string, string>
) => Promise<OutputLine[]>

// 工厂函数：ok() / err() / info() / warn()
// 自动生成 id 和 timestamp，调用方不需要填
```

---

## UI 配色规范

| 用途 | 颜色 |
|------|------|
| 背景 | #0D0D0D |
| 输入区/卡片背景 | #1A1A1A |
| 边框 | #2A2A2A |
| cmd 回显 | #888888 |
| success | #4EC9B0 |
| info | #9CDCFE |
| warn | #CE9178 |
| error | #F44747 |

字体：monospace，正文 fontSize 13

---

## 插件系统工作原理

用户输入 'sysinfo full' 的完整流程：

1. CommandParser 解析 → namespace='sysinfo', action='full'
2. CapabilityDispatcher 在 handlers Map 找不到 'sysinfo'
3. 转到 PluginRegistry.resolve('sysinfo')
4. 找到 SysInfoPlugin
5. PluginSandbox.createContext(plugin) 创建 PluginContextImpl
6. plugin.execute('full', [], flags, ctx) 执行
7. ctx.println() 把输出收集到 ctx._lines[]
8. 返回 [...ctx.getLines(), ...pluginLines] 合并
9. appendLines() 显示到终端

关键点：ctx.println() 收集输出，getLines() 取出，两个来源合并。

---

## SSH 工作原理

鸿蒙微内核没有 execve，不能本地跑 Linux。

SSH 通过 WebSSH 网关实现：
- 用户在 Linux 服务器部署 HTTP 网关
- 网关接收 POST /exec { host, user, port, command }
- 网关用 ssh2 连接目标服务器执行命令
- 返回 { output: string, exitCode: number }

网关示例（Node.js）在 README.md 里。

---

## 插件市场方案（免费）

不需要服务器，用 GitHub raw 文件当注册表：

registry.json 放在仓库 plugin-registry/ 目录：
```json
{
  "plugins": [
    {
      "id": "com.sct.gittools",
      "name": "Git Tools",
      "version": "1.0.0",
      "downloadUrl": "https://github.com/.../releases/sct-gittools.sct"
    }
  ]
}
```

plugin install 时 fetch raw.githubusercontent.com 读取这个文件，
找到对应插件下载地址，下载 .sct 包安装。完全免费。

---

## 待完成功能（优先级排序）

### 高优先级
- GitHub 提交（README.md 还没提交）
- 真机测试（预览器数据是假的）
- SSH 网关调通（跑起来测试 ssh exec 全流程）
- plugin install 真实流程（下载 .sct 包，解析，动态注册）

### 中优先级
- 插件市场后端（GitHub raw 注册表，免费）
- 插件 SDK 文档（给外部开发者）
- 多会话 Tab 完善

### 低优先级（需要独立 NDK 工程）
- NDK 层（libpython.so / liblua.so / NAPI 桥接）
- sct 包管理（NDK 做完后才有意义）

---

## 已知问题

1. 预览器数据为空 — deviceInfo/batteryInfo/hidebug 预览器返回空值，真机正常
2. getContext() 废弃警告 — 只是 WARN，不影响运行
3. PluginSandbox 多处 WARN — Function may throw exceptions，不影响运行
4. 截图功能不可用 — API 版本变更，已标注暂不可用

---

## 开发者信息

- 开发者：Jin
- 开始时间：2026年6月
- 当前版本：v0.1.0
- GitHub：https://github.com/jinbohao1688/SCTerminal.git
- 构建方式：DevEco Studio → Build Hap(s)
