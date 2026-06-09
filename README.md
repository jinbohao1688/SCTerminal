# SCTerminal

**HarmonyOS Developer Command Hub**

> 把鸿蒙设备变成一个可编程的开发者控制台：本地控制设备能力，远程控制 Linux 服务器，插件扩展一切。

![Platform](https://img.shields.io/badge/Platform-HarmonyOS%20NEXT-blue)
![API](https://img.shields.io/badge/API-12%2B-green)
![Language](https://img.shields.io/badge/Language-ArkTS-orange)
![Status](https://img.shields.io/badge/Status-Early%20Preview-yellow)

> ⚠️ **当前状态：早期预览版（v0.5.0）**
> 部分功能仍在开发或待真机验证，详见下方功能状态表。

---

## 这是什么

SCTerminal 是一个运行在 HarmonyOS NEXT 上的原生开发者工具，提供 CLI 风格的系统能力交互界面。

**不是 Linux runtime，不是 Termux，不是 OS shell 模拟器。**

但我们正在往这个方向演进——通过集成 Termony 编译的 Linux 工具链（busybox / bash / python / curl / git / vim / openssh），SCTerminal 将成为鸿蒙上最接近 Termux 的开发者工具。

---

## 功能状态

| 功能 | 状态 | 说明 |
|------|------|------|
| 命令引擎 | ✅ 可用 | Parser + Dispatcher 完整 |
| device / battery / net | ✅ 可用 | 需真机，预览器数据为空 |
| sensor list | ✅ 可用 | 需真机 |
| hmos bundle / perf / inspect | ✅ 可用 | 需真机，部分权限受限 |
| plugin install / list | ✅ 可用 | GitHub 注册表，国内可能超时 |
| 插件系统 SDK | ✅ 可用 | 第三方插件开发文档已发布 |
| http get / post | ✅ 可用 | |
| fs 文件系统命令 | ✅ 真机验证通过 | 预览器有限制 |
| SSH 远程控制 | 🚧 开发完成，未测试 | 需自行部署 WebSSH 网关 |
| run busybox / bash / python | 🚧 开发完成，待真机验证 | 依赖 HNP 工具包 |
| run curl / git / vim / openssh | 🚧 编译完成，待集成 | aarch64，56MB 工具包 |
| 截图（hmos screenshot）| ❌ 暂不可用 | API 版本变更 |
| sct 包管理 | 🔮 规划中 | 工具链就绪后实现 |

---

## 命令速查

### 系统信息

```
device info          # 设备型号 / OS 版本 / UDID
device model         # 设备型号
device os            # OS 版本详情
battery status       # 电量 / 充电状态 / 温度
net status           # 网络连接状态
net info             # 网络详细信息
sensor list          # 传感器列表
```

### 鸿蒙开发者专属（hmos）

```
hmos bundle list              # 已安装应用列表
hmos bundle info <bundleName> # 应用详细信息
hmos perf cpu                 # CPU 占用
hmos perf mem                 # 内存使用
hmos inspect <bundleName>     # 应用权限和签名
hmos device                   # 设备综合状态
hmos log [--filter=tag]       # 日志工具
```

### 文件系统

```
fs pwd               # 显示当前路径
fs ls [path]         # 列出目录内容
fs cd <dir>          # 切换目录（也可直接用 cd <dir>）
fs cat <file>        # 读取文件
fs write <file> <content>  # 写入文件
fs mkdir <dir>       # 创建目录
fs rm <file>         # 删除文件
fs stat <path>       # 文件信息
fs cp <src> <dst>    # 复制文件
```

所有文件操作在应用沙箱内（~/sct/home），不能访问系统目录。

### Linux 工具链（🚧 待真机验证）

```
run busybox <args>   # 执行 busybox 命令
run bash <cmd>       # 执行 bash 命令
run python <file>    # 运行 Python 脚本
run curl <url>       # HTTP 请求
run git <args>       # Git 操作
run vim <file>       # 编辑文件
run which <tool>     # 查找工具路径
```

内置工具链基于 [Termony](https://github.com/TermonyHQ/Termony) 使用鸿蒙 NDK 工具链交叉编译，aarch64 架构，56MB。

### SSH 远程控制（🚧 未测试）

```
ssh gateway --url=http://your-server:8080   # 配置 WebSSH 网关
ssh connect <host> --user=<user> --port=22  # 连接远程服务器
ssh exec <command>                           # 执行远程命令
ssh status                                   # 查看连接状态
ssh disconnect                               # 断开连接
```

> SSH 功能需要自行部署 WebSSH 网关，见下方说明。

### HTTP 工具

```
http get <url>
http post <url> <body> [--header=K:V]
```

### 插件管理

```
plugin install <id>        # 从插件市场安装
plugin list                # 已安装插件
plugin list --available    # 可用插件
plugin remove <id>         # 卸载插件
```

### 内置命令

```
help       # 所有命令
clear      # 清空输出
history    # 命令历史
```

---

## 插件系统

SCTerminal 支持第三方插件扩展，插件市场基于 GitHub 托管，完全免费。

### 安装插件

```
plugin install com.sct.sysinfo
```

### 开发插件

参考 [plugin-sdk/README.md](./plugin-sdk/README.md)，实现 `SCTerminalPlugin` 接口，提交 PR 即可上架。

---

## Linux 工具链

SCTerminal 内置了用鸿蒙 NDK 工具链交叉编译的 Linux 工具，基于 [Termony](https://github.com/TermonyHQ/Termony) 项目：

| 工具 | 版本 | 说明 |
|------|------|------|
| busybox | 1.36.1 | 基础命令工具集 |
| bash | 5.x | Shell |
| python | 3.13 | Python 解释器 |
| curl | 8.x | HTTP 客户端 |
| git | 2.x | 版本控制 |
| vim | 9.x | 编辑器 |
| openssh | 9.x | SSH 客户端 |

所有工具均为 aarch64 架构，静态/动态链接，可在鸿蒙 NEXT 真机上运行。

---

## SSH 网关部署

SSH 功能通过 WebSSH 网关实现：

```bash
mkdir sct-gateway && cd sct-gateway
npm init -y
npm install express ssh2

cat > gateway.js << 'GATEWAY'
const express = require('express')
const { Client } = require('ssh2')
const app = express()
app.use(express.json())

app.post('/exec', (req, res) => {
  const { host, user, port, command, password } = req.body
  const conn = new Client()
  conn.on('ready', () => {
    conn.exec(command, (err, stream) => {
      if (err) { res.json({ output: err.message, exitCode: 1 }); return }
      let output = ''
      stream.on('data', d => output += d.toString())
      stream.stderr.on('data', d => output += d.toString())
      stream.on('close', code => {
        res.json({ output, exitCode: code })
        conn.end()
      })
    })
  }).on('error', e => {
    res.json({ output: e.message, exitCode: 1 })
  }).connect({ host, port: port || 22, username: user, password })
})

app.get('/ping', (req, res) => res.json({ status: 'ok' }))
app.listen(8080, '0.0.0.0', () => console.log('Gateway on :8080'))
GATEWAY

node gateway.js
```

然后在 SCTerminal：

```
ssh gateway --url=http://你的IP:8080
ssh connect 目标主机 --user=root
ssh exec ls -la
```

---

## 环境要求

- DevEco Studio 5.0+
- HarmonyOS NEXT SDK API 12+
- 真机（预览器功能受限）

---

## 开发环境搭建

```bash
git clone https://github.com/jinbohao1688/SCTerminal.git
# 用 DevEco Studio 打开
# Build → Build Hap(s)
# 连接真机 Run
```

---

## 路线图

- [x] 命令引擎（Parser + Dispatcher）
- [x] 本地系统能力（device / battery / net / sensor）
- [x] hmos 开发者命令组
- [x] 文件系统命令（fs）
- [x] 插件系统（SDK + 市场 + 文档）
- [x] HTTP 工具
- [x] NAPI C++ 子进程执行模块
- [x] Linux 工具链编译（busybox / bash / python / curl / git / vim / openssh）
- [x] SSH 架构
- [ ] Linux 工具链真机验证
- [ ] SSH 端到端验证
- [ ] sct 包管理
- [ ] Dashboard GUI 页面
- [ ] 插件市场 Web 页面

---

## 贡献

- 写插件：参考 [plugin-sdk/README.md](./plugin-sdk/README.md)
- 报 bug：提 Issue
- 提 PR：欢迎

---

## 致谢

Linux 工具链基于 [Termony](https://github.com/TermonyHQ/Termony) 项目，使用鸿蒙 NDK 工具链交叉编译。

---

## License

MIT
