package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

Game_Memory :: struct {
  camera:      Camera,
  pass:        sg.Pass_Action,
  cube:        Entity,
  transparent: Entity,
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  g.cube.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(QUAD_VERTICES)})
  g.cube.bind.index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(QUAD_INDICES)},
  )

  g.cube.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      layout = {attrs = {ATTR_base_a_pos = {format = .FLOAT3}}},
      index_type = .UINT16,
    },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  model := linalg.matrix4_translate_f32({0, 0, 0})
  vs_params := Vs_Params {
    mvp = projection * view * model,
  }

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  // cube
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 6, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
