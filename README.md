# SCTerminal

**HarmonyOS Developer Command Hub**

> 把鸿蒙设备变成一个可编程的开发者控制台：本地控制设备能力，远程控制 Linux 服务器，插件扩展一切。

![Platform](https://img.shields.io/badge/Platform-HarmonyOS%20NEXT-blue)
![API](https://img.shields.io/badge/API-12%2B-green)
![Language](https://img.shields.io/badge/Language-ArkTS-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 这是什么

SCTerminal 是一个运行在 HarmonyOS NEXT 上的原生开发者工具，提供 CLI 风格的系统能力交互界面。

它不是 Linux runtime，不是 Termux，不是 OS shell 模拟器。

它是一个**开发者能力中枢**：

- 用命令行方式查询和控制鸿蒙系统能力
- 通过 SSH 把手机变成远程 Linux 控制台
- 通过插件系统让社区无限扩展

---

## 功能概览

### 本地系统能力

```
device info          # 设备型号 / OS 版本 / UDID
device model         # 设备型号
device os            # OS 详细版本

battery status       # 电量 / 充电状态 / 温度 / 健康状态

net status           # 网络连接状态 / 类型
net info             # 网络详细信息

sensor list          # 列出所有传感器

file list            # 沙箱文件列表
file stat <name>     # 文件详细信息
file read <name>     # 读取文件内容
```

### 鸿蒙开发者专属命令（hmos）

```
hmos bundle list              # 列出已安装应用
hmos bundle info <bundleName> # 应用详细信息
hmos perf cpu                 # CPU 性能信息
hmos perf mem                 # 内存使用情况
hmos log [--filter=tag]       # 日志工具
hmos screenshot               # 截图
hmos inspect <bundleName>     # 检查应用权限和签名
hmos device                   # 设备综合状态
```

### SSH 远程控制

```
ssh gateway --url=http://your-server:8080   # 配置 WebSSH 网关
ssh connect <host> --user=<user> --port=22  # 连接远程服务器
ssh exec <command>                           # 执行远程命令
ssh status                                   # 查看连接状态
ssh disconnect                               # 断开连接
```

### HTTP 工具

```
http get <url>                    # GET 请求
http post <url> <body>            # POST 请求（支持 --header=K:V）
```

### 内置命令

```
help       # 显示所有命令
clear      # 清空输出
history    # 命令历史
```

---

## 插件系统

SCTerminal 支持第三方插件扩展。任何开发者都可以编写插件，添加新的命令组。

### 安装插件

```
plugin install com.author.pluginname   # 从插件市场
plugin install https://github.com/...  # 从 URL
plugin list                            # 查看已安装插件
plugin remove com.author.pluginname    # 卸载插件
```

### 开发插件

实现 `SCTerminalPlugin` 接口：

```typescript
import { SCTerminalPlugin, PluginManifest, PluginCommand, PluginContext } from './plugin/PluginSDK'
import { OutputLine } from './capabilities/types'

export class MyPlugin implements SCTerminalPlugin {
  manifest: PluginManifest = {
    id: 'com.yourname.myplugin',
    name: 'My Plugin',
    version: '1.0.0',
    author: 'Your Name',
    description: '插件描述',
    permissions: [],
    minSCTVersion: '1.0.0'
  }

  commands: PluginCommand[] = [
    {
      namespace: 'myplugin',
      action: 'hello',
      description: '打个招呼',
      usage: 'myplugin hello'
    }
  ]

  async execute(
    action: string,
    args: string[],
    flags: Map<string, string>,
    ctx: PluginContext
  ): Promise<OutputLine[]> {
    if (action === 'hello') {
      ctx.println('Hello from MyPlugin!', 'success')
    }
    return []
  }
}
```

插件可以使用的沙箱 API（通过 `PluginContext`）：

| API | 说明 |
|-----|------|
| `ctx.println(text, type)` | 输出到终端 |
| `ctx.readFile(path)` | 读取沙箱文件 |
| `ctx.writeFile(path, content)` | 写入沙箱文件 |
| `ctx.fetch(url)` | HTTPS 请求 |
| `ctx.requestPermission(perms)` | 申请权限 |
| `ctx.storage.get/set/delete` | 插件独立 KV 存储 |

---

## 项目结构

```
entry/src/main/ets/
├── pages/              # 页面
│   ├── TerminalPage.ets
│   └── PluginManagerPage.ets
├── components/         # UI 组件
│   ├── TerminalView.ets
│   ├── CommandInput.ets
│   ├── StatusBar.ets
│   └── TabBar.ets
├── engine/             # 命令引擎
│   ├── CommandParser.ets
│   └── CapabilityDispatcher.ets
├── capabilities/       # 本地系统能力
│   ├── types.ets
│   ├── deviceCapability.ets
│   ├── batteryCapability.ets
│   ├── networkCapability.ets
│   ├── sensorCapability.ets
│   ├── fileCapability.ets
│   └── HmosCapability.ets
├── remote/             # 远程能力
│   ├── SshCapability.ets
│   └── HttpCapability.ets
├── plugin/             # 插件系统
│   ├── PluginSDK.ets
│   ├── PluginRegistry.ets
│   ├── PluginSandbox.ets
│   └── PluginManifest.ets
├── plugins/            # 内置插件
│   └── SysInfoPlugin.ets
├── store/              # 状态管理
│   ├── TerminalStore.ets
│   └── HistoryStore.ets
└── utils/
    ├── color.ets
    ├── permission.ets
    └── time.ets
```

---

## 环境要求

- DevEco Studio 5.0+
- HarmonyOS NEXT SDK API 12+
- 真机或 API 12 模拟器

---

## 开发环境搭建

```bash
# 1. 克隆仓库
git clone https://github.com/jinbohao1688/SCTerminal.git

# 2. 用 DevEco Studio 打开项目

# 3. 等待依赖同步完成

# 4. Build → Build Hap(s) 编译

# 5. 连接设备，Run 运行
```

---

## SSH 网关配置

SSH 功能需要你自己部署一个 WebSSH 网关。

```bash
# 在你的 Linux 服务器上
mkdir sct-gateway && cd sct-gateway
npm init -y
npm install express ssh2

# 创建 gateway.js（见 docs/gateway.js）
node gateway.js
```

然后在 SCTerminal 里：

```
ssh gateway --url=http://your-server-ip:8080
ssh connect target-host --user=root --port=22
ssh exec ls -la
```

---

## 路线图

- [x] 命令引擎（Parser + Dispatcher）
- [x] 本地系统能力（device / battery / net / sensor / file）
- [x] 鸿蒙开发者命令组（hmos）
- [x] SSH 远程控制
- [x] HTTP 工具
- [x] 插件系统（SDK + Registry + Sandbox）
- [x] 插件管理 UI
- [ ] 插件市场（在线安装）
- [ ] NDK 运行时（Python / Lua / QuickJS）
- [ ] sct 包管理
- [ ] 多会话 Tab 完整支持
- [ ] 插件 SDK 文档站

---

## 贡献

欢迎提交插件、报告 bug、提出功能建议。

插件开发参考 `entry/src/main/ets/plugins/SysInfoPlugin.ets`。

---

## License

MIT
