import { PluginManifest } from '../plugin/PluginSDK'
import { pluginRegistry } from '../plugin/PluginRegistry'
import { COLORS } from '../utils/color'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

interface MarketPlugin {
  id: string
  name: string
  version: string
  author: string
  description: string
  downloads: number
}

interface InstalledCard {
  id: string
  name: string
  version: string
  author: string
  description: string
  commands: string[]
}

const MARKET_PLUGINS: MarketPlugin[] = [
  { id: 'com.sct.sysinfo',    name: 'SysInfo',      version: '1.0.0', author: 'SCTerminal', description: '系统信息增强',       downloads: 1200 },
  { id: 'com.sct.gittools',   name: 'Git Tools',    version: '0.9.0', author: 'community',  description: 'Git 常用操作封装',    downloads: 890 },
  { id: 'com.sct.httptest',   name: 'HTTP Tester',  version: '1.1.0', author: 'community',  description: 'API 接口测试工具',    downloads: 654 },
  { id: 'com.sct.jsonformat', name: 'JSON Format',  version: '1.0.2', author: 'community',  description: 'JSON 格式化和查询',   downloads: 432 },
  { id: 'com.sct.base64',     name: 'Base64 Tools', version: '1.0.0', author: 'community',  description: 'Base64 编解码工具',   downloads: 321 },
]

@Entry
@Component
struct PluginManagerPage {
  @State currentTab: number = 0
  @State installedCards: InstalledCard[] = []

  aboutToAppear(): void {
    this.refresh()
  }

  private refresh(): void {
    const manifests = pluginRegistry.list()
    const cards: InstalledCard[] = []
    for (let i = 0; i < manifests.length; i++) {
      const m = manifests[i]
      const plugin = pluginRegistry.get(m.id)
      const cmds: string[] = []
      if (plugin !== undefined) {
        for (let j = 0; j < plugin.commands.length; j++) {
          cmds.push(plugin.commands[j].usage)
        }
      }
      const card: InstalledCard = {
        id: m.id,
        name: m.name,
        version: m.version,
        author: m.author,
        description: m.description,
        commands: cmds,
      }
      cards.push(card)
    }
    this.installedCards = cards
  }

  private isInstalled(id: string): boolean {
    for (let i = 0; i < this.installedCards.length; i++) {
      if (this.installedCards[i].id === id) {
        return true
      }
    }
    return false
  }

  build() {
    Column() {
      // Header
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor('#4EC9B0')
          .backgroundColor(Color.Transparent)
          .onClick(() => { router.back() })
        Blank()
        Text('插件管理')
          .fontSize(14)
          .fontColor('#888888')
          .fontFamily('monospace')
        Blank()
        Row().width(60)
      }
      .width('100%')
      .padding(12)

      Divider().height(1).color(COLORS.BORDER)

      // Tabs
      Row() {
        Button('已安装')
          .fontSize(13)
          .fontColor(this.currentTab === 0 ? COLORS.SUCCESS : COLORS.CMD)
          .backgroundColor(this.currentTab === 0 ? '#1A1A1A' : Color.Transparent)
          .layoutWeight(1)
          .onClick(() => { this.currentTab = 0 })

        Button('可用插件')
          .fontSize(13)
          .fontColor(this.currentTab === 1 ? COLORS.SUCCESS : COLORS.CMD)
          .backgroundColor(this.currentTab === 1 ? '#1A1A1A' : Color.Transparent)
          .layoutWeight(1)
          .onClick(() => { this.currentTab = 1 })
      }
      .width('100%')

      Divider().height(1).color(COLORS.BORDER)

      // Installed tab
      if (this.currentTab === 0) {
        if (this.installedCards.length === 0) {
          Column() {
            Text('暂无已安装插件')
              .fontSize(13)
              .fontColor(COLORS.CMD)
              .fontFamily('monospace')
            Text('在终端输入 plugin install 安装')
              .fontSize(12)
              .fontColor(COLORS.CMD)
              .fontFamily('monospace')
              .margin({ top: 4 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.installedCards, (card: InstalledCard) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(card.name)
                      .fontSize(14)
                      .fontColor('#CCCCCC')
                      .fontFamily('monospace')
                    Blank()
                    Text('v' + card.version)
                      .fontSize(12)
                      .fontColor('#444444')
                      .fontFamily('monospace')
                  }
                  .width('100%')

                  Text(card.author)
                    .fontSize(11)
                    .fontColor('#555555')
                    .fontFamily('monospace')

                  Text(card.description)
                    .fontSize(12)
                    .fontColor('#777777')
                    .fontFamily('monospace')
                    .margin({ top: 4 })

                  ForEach(card.commands, (cmd: string) => {
                    Text('  $ ' + cmd)
                      .fontSize(12)
                      .fontColor('#4EC9B0')
                      .fontFamily('monospace')
                      .margin({ top: 2 })
                  }, (cmd: string) => 'cmd_' + card.id + '_' + cmd)

                  Row() {
                    Blank()
                    Text('卸载')
                      .fontSize(12)
                      .fontColor('#F44747')
                      .onClick(async () => {
                        try {
                          await pluginRegistry.uninstall(card.id)
                          this.refresh()
                        } catch (e) {
                          const msg = (e as Error).message
                          promptAction.showToast({ message: '卸载失败: ' + msg })
                        }
                      })
                  }
                  .width('100%')
                  .margin({ top: 8 })
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#1A1A1A')
                .borderRadius(8)
                .border({ width: 1, color: '#2A2A2A' })
                .margin({ left: 12, right: 12, top: 6, bottom: 6 })
              }
            }, (card: InstalledCard) => card.id)
          }
          .width('100%')
          .layoutWeight(1)
        }
      }

      // Available tab
      if (this.currentTab === 1) {
        List() {
          ForEach(MARKET_PLUGINS, (mp: MarketPlugin) => {
            ListItem() {
              Column() {
                Row() {
                  Text(mp.name)
                    .fontSize(14)
                    .fontColor('#CCCCCC')
                    .fontFamily('monospace')
                  Blank()
                  Text('v' + mp.version)
                    .fontSize(12)
                    .fontColor('#444444')
                    .fontFamily('monospace')
                    .margin({ right: 8 })
                  Text(mp.downloads + ' 次下载')
                    .fontSize(11)
                    .fontColor('#555555')
                    .fontFamily('monospace')
                }
                .width('100%')

                Text(mp.author)
                  .fontSize(11)
                  .fontColor('#555555')
                  .fontFamily('monospace')

                Text(mp.description)
                  .fontSize(12)
                  .fontColor('#777777')
                  .fontFamily('monospace')
                  .margin({ top: 4 })

                Row() {
                  Blank()
                  if (this.isInstalled(mp.id)) {
                    Button('已安装')
                      .fontSize(11)
                      .fontColor('#555555')
                      .backgroundColor(Color.Transparent)
                  } else {
                    Button('安装')
                      .fontSize(11)
                      .fontColor(COLORS.SUCCESS)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        promptAction.showToast({ message: '请在终端输入: plugin install ' + mp.id })
                      })
                  }
                }
                .width('100%')
                .margin({ top: 8 })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#1A1A1A')
              .borderRadius(8)
              .border({ width: 1, color: '#2A2A2A' })
              .margin({ left: 12, right: 12, top: 6, bottom: 6 })
            }
          }, (mp: MarketPlugin) => mp.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG)
  }
}
