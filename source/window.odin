/*
This file is the starting point of your game.

Some importants procedures:
- game_init: Initializes sokol_gfx and sets up the game state.
- game_frame: Called one per frame, do your game logic and rendering in here.
- game_cleanup: Called on shutdown of game, cleanup memory etc.

The hot reload compiles the contents of this folder into a game DLL. A host
application loads that DLL and calls the procedures of the DLL. 

Special procedures that help facilitate the hot reload:
- game_memory: Run just before a hot reload. The hot reload host application can
	that way keep a pointer to the game's memory and feed it to the new game DLL
	after the hot reload is complete.
- game_hot_reloaded: Sets the `g` global variable in the new game DLL. The value
	comes from the value the host application got from game_memory before the
	hot reload.

When release or web builds are made, then this whole package is just
treated as a normal Odin package. No DLL is created.

The hot applications use sokol_app to open the window. They use the settings
returned by the `game_app_default_desc` procedure.
*/

package game

import sapp "sokol/app"
import sg "sokol/gfx"
import slog "sokol/log"

g: ^Game_Memory
delta_time: f32

@(export)
game_app_default_desc :: proc() -> sapp.Desc {
  return {
    width = 1280,
    height = 720,
    sample_count = 4,
    high_dpi = true,
    window_title = "Odin + Sokol hot reload template",
    icon = {sokol_default = true},
    logger = {func = slog.func},
    html5_update_document_title = true,
  }
}

@(export)
game_cleanup :: proc() {
  sg.shutdown()
  free(g)
}

@(export)
game_memory :: proc() -> rawptr {
  return g
}

@(export)
game_memory_size :: proc() -> int {
  return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
  g = (^Game_Memory)(mem)

  // Here you can also set your own global variables. A good idea is to make
  // your global variables into pointers that point to something inside
  // `g`. Then that state carries over between hot reloads.
}

force_reset: bool

@(export)
game_force_restart :: proc() -> bool {
  return force_reset
}

@(export)
game_event :: proc(e: ^sapp.Event) {
  if e.type == .KEY_DOWN {
    if e.key_code == .R do force_reset = true
    if e.key_code == .Q do sapp.request_quit()
    if e.key_code == .T do DEBUG_TEXT = !DEBUG_TEXT
  }

  if e.type == .RESIZED {
    create_offscreen(e.framebuffer_width, e.framebuffer_height)
  }

  camera_process_input(e)
}
