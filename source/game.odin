package game

import "core:fmt"
import "core:math"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

Game_Memory :: struct {
  camera:  Camera,
  pass:    sg.Pass_Action,
  display: Entity,
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  g.display.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      layout = {attrs = {ATTR_base_pos = {format = .FLOAT2}}},
      cull_mode = .FRONT,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
    },
  )

  g.display.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(QUAD_VERTICES)})

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())
  time = f32(stm.sec(stm.now()))
  fs_params := Fs_Params {
    time       = time,
    resolution = Vec2{sapp.widthf(), sapp.heightf()},
    mouse      = Vec2{g.camera.mouse_x, g.camera.mouse_y},
  }

  // fmt.println(time, math.abs(math.sin(time)))

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.display.pip)
  sg.apply_bindings(g.display.bind)
  sg.apply_uniforms(UB_fs_params, data = sg_range(&fs_params))
  sg.draw(0, 6, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
