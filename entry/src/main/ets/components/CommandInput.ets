import { KeyCode } from '@kit.InputKit'
import { terminalStore } from '../store/TerminalStore'

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
        .color('#2A2A2A')
      Row() {
        Text(terminalStore.currentPath + '❯')
          .fontSize(12)
          .fontColor('#CCCCCC')
          .fontFamily('monospace')
          .constraintSize({ maxWidth: 200 })

        Button('↑')
          .fontSize(14)
          .fontColor('#444444')
          .backgroundColor(Color.Transparent)
          .width(28)
          .height(28)
          .padding(0)
          .onClick(() => { this.navigateUp() })

        Button('↓')
          .fontSize(14)
          .fontColor('#444444')
          .backgroundColor(Color.Transparent)
          .width(28)
          .height(28)
          .padding(0)
          .onClick(() => { this.navigateDown() })

        TextInput({ text: this.currentInput, placeholder: '输入命令...' })
          .fontSize(13)
          .fontFamily('monospace')
          .fontColor('#9CDCFE')
          .placeholderColor('#333333')
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

        Button('↵')
          .fontSize(18)
          .fontColor('#4EC9B0')
          .backgroundColor(Color.Transparent)
          .width(36)
          .height(28)
          .padding(0)
          .onClick(() => { this.submitCmd() })
      }
      .width('100%')
      .height(52)
      .padding({ left: 12, right: 8 })
    }
    .width('100%')
    .backgroundColor('#1A1A1A')
  }
}
