package game

import "core:fmt"

import sapp "sokol/app"
import sdtx "sokol/debugtext"
import slog "sokol/log"

DEBUG_TEXT :: false

debug_init :: proc() {
  sdtx.setup({fonts = {0 = sdtx.font_oric()}, logger = {func = slog.func}})
}

debug_process :: proc() {
  if !DEBUG_TEXT do return

  sdtx.canvas(sapp.widthf() / 4, sapp.heightf() / 4)
  sdtx.origin(1, 1)

  fps := 1.0 / delta_time
  print_text("FPS: %d", u8(fps))

  print_text("FREE CAMERA: %v", FREE_CAMERA)
  print_text("CAMERA: %#w", g.camera)

  sdtx.draw()
}

print_text :: proc(format: string, args: ..any) {
  sdtx.puts(fmt.caprintf(format, ..args, newline = true, allocator = context.temp_allocator))
  sdtx.move_y(0.5)
}
