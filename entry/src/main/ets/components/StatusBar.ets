import { formatTime } from '../utils/time'

@Component
export struct StatusBar {
  @State clock: string = ''

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
    Row() {
      Text('SCT v1.0')
        .fontSize(11)
        .fontColor('#555555')
        .fontFamily('monospace')
      Blank()
      Text(this.clock)
        .fontSize(11)
        .fontColor('#555555')
        .fontFamily('monospace')
    }
    .width('100%')
    .height(36)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#111111')
  }
}
