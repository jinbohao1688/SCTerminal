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
          if (line.text.length === 0) {
            // skip empty output
          } else if (line.type === 'cmd') {
            Row() {
              Text('➜')
                .fontSize(13)
                .fontColor(COLORS.SUCCESS)
                .fontFamily('monospace')
                .margin({ right: 8 })
              Text(line.text)
                .fontSize(13)
                .fontColor(COLORS.CMD)
                .fontFamily('monospace')
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
          } else {
            Row() {
              Text(formatTime(line.timestamp))
                .fontSize(11)
                .fontColor('#333333')
                .fontFamily('monospace')
                .width(56)
              Text(this.prefix(line.type) + line.text)
                .fontSize(13)
                .fontColor(this.typeColor(line.type))
                .fontFamily('monospace')
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
          }
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
      case 'success': return COLORS.SUCCESS
      case 'info': return COLORS.INFO
      case 'warn': return COLORS.WARN
      case 'error': return COLORS.ERROR
      default: return COLORS.INFO
    }
  }

  private prefix(type: string): string {
    switch (type) {
      case 'error': return '✕ '
      case 'warn': return '⚠ '
      case 'success': return '  '
      case 'info': return ''
      default: return ''
    }
  }
}
