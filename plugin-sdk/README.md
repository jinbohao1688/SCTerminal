# SCTerminal 插件开发指南

## 快速开始

### 1. 创建插件文件

在你的项目里创建 MyPlugin.ets：

```typescript
import { SCTerminalPlugin, PluginManifest, PluginCommand, PluginContext } from './PluginSDK'
import { OutputLine } from './types'

export class MyPlugin implements SCTerminalPlugin {
  manifest: PluginManifest = {
    id: 'com.yourname.myplugin',      // 唯一 ID，用反向域名
    name: 'My Plugin',
    version: '1.0.0',
    author: 'Your Name',
    description: '插件描述',
    permissions: [],                   // 需要的鸿蒙权限
    minSCTVersion: '1.0.0'
  }

  commands: PluginCommand[] = [
    {
      namespace: 'myplugin',           // 命令前缀，用户输入的第一个词
      action: 'hello',                 // 子命令
      description: '打个招呼',
      usage: 'myplugin hello [name]'
    }
  ]

  async onInstall(ctx: PluginContext): Promise<void> {
    ctx.println('插件安装成功', 'success')
  }

  async execute(
    action: string,
    args: string[],
    flags: Map<string, string>,
    ctx: PluginContext
  ): Promise<OutputLine[]> {
    if (action === 'hello') {
      const name = args.length > 0 ? args[0] : 'World'
      ctx.println('Hello, ' + name + '!', 'success')
    } else {
      ctx.println('未知操作: ' + action, 'warn')
    }
    return []
  }
}
```

### 2. 发布插件包

创建 myplugin.json（插件包格式）：

```json
{
  "manifest": {
    "id": "com.yourname.myplugin",
    "name": "My Plugin",
    "version": "1.0.0",
    "author": "Your Name",
    "description": "插件描述",
    "permissions": [],
    "minSCTVersion": "1.0.0"
  },
  "code": ""
}
```

把这个文件放到 GitHub 上，
然后提交 PR 到 SCTerminal 仓库的 plugin-registry/registry.json，
加入你的插件信息。

### 3. PluginContext API

插件只能通过 ctx 访问系统，不能直接 import @ohos.\*

| API | 说明 | 示例 |
|-----|------|------|
| ctx.println(text, type) | 输出到终端 | ctx.println('hello', 'success') |
| ctx.readFile(path) | 读取沙箱文件 | await ctx.readFile('data.txt') |
| ctx.writeFile(path, content) | 写入沙箱文件 | await ctx.writeFile('out.txt', 'hello') |
| ctx.fetch(url) | HTTPS 请求 | await ctx.fetch('https://api.example.com') |
| ctx.requestPermission(perms) | 申请权限 | await ctx.requestPermission(['ohos.permission.xxx']) |
| ctx.storage.get(key) | 读取 KV 存储 | await ctx.storage.get('mykey') |
| ctx.storage.set(key, value) | 写入 KV 存储 | await ctx.storage.set('mykey', 'val') |
| ctx.storage.delete(key) | 删除 KV 存储 | await ctx.storage.delete('mykey') |

type 可选值：'success' | 'error' | 'info' | 'warn'

### 4. OutputLine 类型

execute 返回 OutputLine[]，也可以通过 ctx.println() 输出。
两种方式的输出都会显示在终端里。

推荐用 ctx.println() 输出，return [] 即可。
需要精确控制输出顺序时，手动构建 OutputLine[] 返回。

### 5. ArkTS 限制（重要）

SCTerminal 运行在 HarmonyOS NEXT，使用 ArkTS 严格模式：

- 不能用 any / unknown 类型
- 不能用 ?? 和 ?.
- catch(e) 里用 const msg = (e as Error).message
- 不能用解构赋值
- 不能用动态索引访问 obj[key]
- 所有对象字面量必须有对应 interface

### 6. 示例插件

参考 entry/src/main/ets/plugins/SysInfoPlugin.ets
这是一个完整的内置示例插件。

### 7. 提交到插件市场

1. Fork https://github.com/jinbohao1688/SCTerminal
2. 在 plugin-registry/packages/ 下添加 yourplugin.json
3. 在 plugin-registry/registry.json 里添加插件信息：

```json
{
  "id": "com.yourname.myplugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "插件描述",
  "downloadUrl": "https://raw.githubusercontent.com/yourname/repo/main/myplugin.json",
  "bundled": false
}
```

4. 提交 PR，审核通过后插件上架
