import { COLORS } from '../utils/color'
import { KeyCode } from '@kit.InputKit'

@Component
export struct CommandInput {
  @Prop inputHistory: string[]
  @State currentInput: string = ''
  @State historyIdx: number = -1

  onSubmit?: (cmd: string) => void

  private submitCmd(): void {
    const cmd = this.currentInput.trim()
    if (cmd.length === 0) return
    this.currentInput = ''
    this.historyIdx = -1
    if (this.onSubmit !== undefined) {
      this.onSubmit(cmd)
    }
  }

  private navigateUp(): void {
    if (this.inputHistory.length === 0) return
    if (this.historyIdx === -1) {
      this.historyIdx = this.inputHistory.length - 1
    } else if (this.historyIdx > 0) {
      this.historyIdx--
    }
    this.currentInput = this.inputHistory[this.historyIdx]
  }

  private navigateDown(): void {
    if (this.historyIdx === -1) return
    if (this.historyIdx < this.inputHistory.length - 1) {
      this.historyIdx++
      this.currentInput = this.inputHistory[this.historyIdx]
    } else {
      this.historyIdx = -1
      this.currentInput = ''
    }
  }

  build() {
    Column() {
      Divider()
        .height(1)
        .color(COLORS.BORDER)
      Row() {
        Text('➜ ~')
          .fontSize(14)
          .fontColor(COLORS.SUCCESS)
          .fontFamily('monospace')
          .margin({ right: 8 })

        Button('↑')
          .fontSize(16)
          .fontColor('#555555')
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .padding(0)
          .onClick(() => { this.navigateUp() })

        Button('↓')
          .fontSize(16)
          .fontColor('#555555')
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .padding(0)
          .margin({ right: 4 })
          .onClick(() => { this.navigateDown() })

        Button('↵')
          .fontSize(16)
          .fontColor('#555555')
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .padding(0)
          .margin({ right: 4 })
          .onClick(() => { this.submitCmd() })

        TextInput({ text: this.currentInput, placeholder: '输入命令…' })
          .fontSize(13)
          .fontFamily('monospace')
          .fontColor(COLORS.INFO)
          .placeholderColor(COLORS.CMD)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.currentInput = value
            this.historyIdx = -1
          })
          .onSubmit(() => { this.submitCmd() })
          .onKeyEvent((event: KeyEvent) => {
            if (event.type !== KeyType.Down) return
            if (event.keyCode === KeyCode.KEYCODE_DPAD_UP) {
              this.navigateUp()
            } else if (event.keyCode === KeyCode.KEYCODE_DPAD_DOWN) {
              this.navigateDown()
            }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
    .width('100%')
    .backgroundColor(COLORS.INPUT_BG)
  }
}
