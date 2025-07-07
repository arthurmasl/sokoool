package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

Game_Memory :: struct {
  camera:  Camera,
  pass:    sg.Pass_Action,
  cube:    Entity,
  outline: Entity,
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  vb := sg.make_buffer({data = sg_range(CUBE_VERTICES)})
  ib := sg.make_buffer({usage = {index_buffer = true}, data = sg_range(CUBE_INDICES)})

  g.cube.bind.vertex_buffers[0] = vb
  g.cube.bind.index_buffer = ib
  g.cube.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      layout = {
        attrs = {ATTR_base_a_pos = {format = .FLOAT3}, ATTR_base_a_color = {format = .FLOAT4}},
      },
      stencil = {
        front = {compare = .ALWAYS, pass_op = .REPLACE},
        back = {compare = .ALWAYS, pass_op = .REPLACE},
        enabled = true,
        read_mask = 0xFF,
        write_mask = 0xFF,
        ref = 1,
      },
      index_type = .UINT16,
      cull_mode = .BACK,
      depth = {write_enabled = true, compare = .LESS_EQUAL},
    },
  )
  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.8, 0.8, 1.0}}},
  }

  // outline
  g.outline.bind.vertex_buffers[0] = vb
  g.outline.bind.index_buffer = ib

  g.outline.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(outline_shader_desc(sg.query_backend())),
      layout = {attrs = {ATTR_outline_a_pos = {format = .FLOAT3}}, buffers = {0 = {stride = 28}}},
      stencil = {
        front = {compare = .NOT_EQUAL, pass_op = .REPLACE},
        back = {compare = .NOT_EQUAL, pass_op = .REPLACE},
        enabled = true,
        read_mask = 0xFF,
        write_mask = 0x00,
        ref = 1,
      },
      depth = {compare = .ALWAYS},
      index_type = .UINT16,
      cull_mode = .BACK,
    },
  )
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

  // outline
  sg.apply_pipeline(g.outline.pip)
  sg.apply_bindings(g.outline.bind)
  model *= linalg.matrix4_scale_f32({1.1, 1.1, 1.1})
  vs_params.mvp = projection * view * model
  sg.apply_uniforms(UB_vs_params_outline, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
