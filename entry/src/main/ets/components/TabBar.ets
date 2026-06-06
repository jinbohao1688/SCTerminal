import { COLORS } from '../utils/color'

@Component
export struct TabBar {
  @Prop sessions: string[]
  @Prop activeSession: string
  onSwitch?: (id: string) => void
  onClose?: (id: string) => void

  build() {
    Scroll() {
      Row() {
        ForEach(this.sessions, (id: string) => {
          Text(id)
            .fontSize(12)
            .fontFamily('monospace')
            .fontColor(id === this.activeSession ? COLORS.INFO : COLORS.CMD)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(id === this.activeSession ? '#1A2A3A' : Color.Transparent)
            .borderRadius(4)
            .margin({ right: 4 })
            .onClick(() => {
              if (this.onSwitch !== undefined) {
                this.onSwitch(id)
              }
            })
            .gesture(
              LongPressGesture()
                .onAction(() => {
                  if (this.sessions.length <= 1) return
                  if (this.onClose !== undefined) {
                    this.onClose(id)
                  }
                })
            )
        })
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(32)
    .backgroundColor(COLORS.BG)
    .scrollBar(BarState.Off)
  }
}
