import { OutputLine } from '../capabilities/types'
import { COLORS } from '../utils/color'
import { formatTime } from '../utils/time'

@Component
export struct TerminalView {
  @Prop lines: OutputLine[]

  private scroller: Scroller = new Scroller()

  build() {
    List({ scroller: this.scroller }) {
      ForEach(this.lines, (line: OutputLine) => {
        ListItem() {
          Row() {
            Text(formatTime(line.timestamp))
              .fontSize(11)
              .fontColor('#444444')
              .fontFamily('monospace')
              .margin({ right: 8 })
            Text(line.text)
              .fontSize(13)
              .fontColor(this.typeColor(line.type))
              .fontFamily('monospace')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 2, bottom: 2 })
        }
      }, (line: OutputLine) => line.id)
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(COLORS.BG)
    .onAreaChange(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    })
  }

  private typeColor(type: string): string {
    switch (type) {
      case 'cmd': return COLORS.CMD
      case 'success': return COLORS.SUCCESS
      case 'info': return COLORS.INFO
      case 'warn': return COLORS.WARN
      case 'error': return COLORS.ERROR
      default: return COLORS.INFO
    }
  }
}
