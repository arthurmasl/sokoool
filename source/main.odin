package game

import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

}

@(export)
game_frame :: proc() {
  pass_action := sg.Pass_Action {
    colors = {0 = {load_action = .CLEAR, clear_value = {1.41, 0.68, 0.83, 1}}},
  }
  sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}

@(export)
game_event :: proc(e: ^sapp.Event) {
  #partial switch e.type {
  case .KEY_DOWN:
    if e.key_code == .R {
      force_reset = true
    }
  }
}
