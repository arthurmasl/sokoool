package game

import sapp "sokol/app"

@(export)
game_event :: proc(e: ^sapp.Event) {
  #partial switch e.type {
  case .KEY_DOWN:
    if e.key_code == .R {
      force_reset = true
    }
  }
}
