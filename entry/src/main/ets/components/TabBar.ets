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
          Column() {
            Text(id)
              .fontSize(12)
              .fontFamily('monospace')
              .fontColor(id === this.activeSession ? '#4EC9B0' : '#444444')
              .padding({ left: 8, right: 8, top: 6, bottom: 2 })
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
            if (id === this.activeSession) {
              Divider()
                .height(2)
                .width(32)
                .color('#4EC9B0')
            }
          }
          .margin({ right: 24 })
        })
      }
      .padding({ left: 12, right: 12, top: 4, bottom: 0 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(32)
    .backgroundColor('#0D0D0D')
    .scrollBar(BarState.Off)
  }
}
