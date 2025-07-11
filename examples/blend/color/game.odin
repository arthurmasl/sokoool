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

  // default
  g.cube.bind.storage_buffers = {
    SBUF_ssbo = sg.make_buffer({usage = {storage_buffer = true}, data = sg_range(CUBE_VERTICES)}),
  }
  g.cube.bind.index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(CUBE_INDICES)},
  )
  g.cube.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      index_type = .UINT16,
      cull_mode = .BACK,
      depth = {write_enabled = true, compare = .LESS_EQUAL},
    },
  )

  // transparent
  g.transparent.bind.storage_buffers = {
    SBUF_ssbo_transparent = sg.make_buffer(
      {usage = {storage_buffer = true}, data = sg_range(CUBE_VERTICES)},
    ),
  }
  g.transparent.bind.index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(CUBE_INDICES)},
  )
  g.transparent.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(transparent_shader_desc(sg.query_backend())),
      index_type = .UINT16,
      // cull_mode = .BACK,
      // depth = {write_enabled = true, compare = .LESS_EQUAL},
      colors = {
        0 = {
          blend = {
            enabled = true,
            src_factor_rgb = .ONE,
            dst_factor_rgb = .ONE,
            op_rgb = .ADD,
            src_factor_alpha = .ONE,
            dst_factor_alpha = .ONE,
            op_alpha = .ADD,
          },
        },
      },
      color_count = 1,
    },
  )

  // pass
  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  model := linalg.matrix4_translate_f32({-1, 1, -1})
  vs_params := Vs_Params {
    mvp = projection * view * model,
  }

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  // cube
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  // transparent
  vs_params_transparent := Vs_Params_Transparent {
    mvp          = projection * view * linalg.matrix4_translate_f32({-1, 1, -1}) * linalg.matrix4_scale_f32({2, 2, 2}),
    u_time       = f32(stm.sec(stm.now())),
    u_resolution = Vec2{sapp.widthf(), sapp.heightf()},
  }
  sg.apply_pipeline(g.transparent.pip)
  sg.apply_bindings(g.transparent.bind)
  sg.apply_uniforms(UB_vs_params_transparent, data = sg_range(&vs_params_transparent))
  sg.draw(0, 36, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
