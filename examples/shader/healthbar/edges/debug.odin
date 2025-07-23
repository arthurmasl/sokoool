package game

import "core:fmt"

import sapp "sokol/app"
import sdtx "sokol/debugtext"
import slog "sokol/log"

DEBUG_TEXT := false
DEBUG_LINES := false

debug_init :: proc() {
  sdtx.setup({fonts = {0 = sdtx.font_oric()}, logger = {func = slog.func}})
}

debug_process :: proc() {
  if !DEBUG_TEXT do return

  sdtx.canvas(sapp.widthf() / 4, sapp.heightf() / 4)
  sdtx.origin(1, 1)

  fps := 1.0 / delta_time
  print_text("FPS: %d", u8(fps))

  print_text("CAMERA: %#w", g.camera)

  sdtx.draw()
}

print_text :: proc(format: string, args: ..any) {
  sdtx.puts(fmt.ctprintf(format, ..args, newline = true))
  sdtx.move_y(0.5)
}
