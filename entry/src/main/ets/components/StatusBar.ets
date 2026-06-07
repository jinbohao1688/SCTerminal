import { formatTime } from '../utils/time'

@Component
export struct StatusBar {
  @State clock: string = ''
  onPluginClick?: () => void

  private timer: number = -1

  aboutToAppear(): void {
    this.tick()
    this.timer = setInterval(() => { this.tick() }, 1000)
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
  }

  private tick(): void {
    this.clock = formatTime(Date.now())
  }

  build() {
    Column() {
      Row() {
        Text('SCT')
          .fontSize(11)
          .fontColor('#4EC9B0')
          .fontFamily('monospace')
          .fontWeight(FontWeight.Bold)
        Text(' v1.0')
          .fontSize(11)
          .fontColor('#444444')
          .fontFamily('monospace')
        Blank()
        if (this.onPluginClick !== undefined) {
          Text('插件')
            .fontSize(12)
            .fontColor('#444444')
            .onClick(() => {
              if (this.onPluginClick !== undefined) {
                this.onPluginClick()
              }
            })
            .margin({ right: 12 })
        }
        Text(this.clock)
          .fontSize(11)
          .fontColor('#444444')
          .fontFamily('monospace')
      }
      .width('100%')
      .height(36)
      .padding({ left: 12, right: 12 })

      Divider()
        .height(1)
        .color('#1A1A1A')
    }
    .width('100%')
    .backgroundColor('#0A0A0A')
  }
}
