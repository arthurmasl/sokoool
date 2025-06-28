package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

Game_Memory :: struct {
  camera:    Camera,
  pass:      sg.Pass_Action,
  cube:      Entity,
  post:      Entity,
  post_pass: sg.Pass_Action,
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  // post-process
  g.post_pass = {
    colors = {0 = {load_action = .DONTCARE}},
    depth = {load_action = .DONTCARE},
    stencil = {load_action = .DONTCARE},
  }

  g.post.bind.samplers[0] = sg.make_sampler({})

  g.post.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(post_shader_desc(sg.query_backend())),
      layout = {
        attrs = {ATTR_post_position = {format = .FLOAT3}, ATTR_post_texcoord = {format = .FLOAT2}},
      },
    },
  )
  
  // odinfmt: disable
  quad := []f32 {
    // pos      uv
    -1, -1,     0, 0,
     1, -1,     1, 0,
    -1,  1,     0, 1,
     1,  1,     1, 1,
  }
  // odinfmt: enable
  g.post.bind.vertex_buffers[0] = sg.make_buffer(
    {data = {ptr = raw_data(quad), size = size_of(quad)}},
  )

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
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  sg.end_pass()

  // post
  sg.begin_pass({action = g.post_pass, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.post.pip)
  sg.apply_bindings(g.post.bind)

  sg.draw(0, 4, 1)
  sg.end_pass()

  sg.commit()

  free_all(context.temp_allocator)
}
