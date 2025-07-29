package game

import "core:fmt"

import sapp "sokol/app"
import sdtx "sokol/debugtext"
import sg "sokol/gfx"
import slog "sokol/log"

DEBUG_TEXT := true
DEBUG_LINES := true

debug_init :: proc() {
  sdtx.setup({fonts = {0 = sdtx.font_oric()}, logger = {func = slog.func}})
}

debug_process :: proc() {
  if !DEBUG_TEXT do return

  sg.apply_viewport(0, 0, sapp.width(), sapp.height(), false)

  sdtx.canvas(sapp.widthf() / 4, sapp.heightf() / 4)
  sdtx.origin(1, 1)

  fps := 1.0 / delta_time
  print_text("FPS: %d", u8(fps))
  // print_text("TRIANGLES: %#w", TRIANGLES)

  print_text("THREADS : %#w", COMPUTE_THREADS)
  print_text("GRID SIZE: %#w", GRID_SIZE)
  print_text("TERRAIN VERTICES: %#w", NUM_TERRAIN_VERTICES)
  print_text("TERRAIN INDICES: %#w", NUM_TERRAIN_INDICES)

  // print_text("CAMERA: %#w", g.camera)

  sdtx.draw()
}

print_text :: proc(format: string, args: ..any) {
  sdtx.puts(fmt.ctprintf(format, ..args, newline = true))
  sdtx.move_y(0.5)
}
