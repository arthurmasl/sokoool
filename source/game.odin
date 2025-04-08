package game

import "core:math/linalg"

import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  g.cube_pos = {0.5, -1, 0}
  g.cube_color = {1.0, 0.5, 0.8}

  g.light_pos = {3.2, 10.0, 3.0}
  g.light_color = {1.0, 1.0, 1.0}

  g.ground_pos = {0, -2, 0}
  g.ground_color = {1.0, 1.0, 0.2}

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  base_shader := base_shader_desc(sg.query_backend())
  light_shader := light_shader_desc(sg.query_backend())

  g.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(CUBE_NORMAL_VERTICES)})

  g.pip_cube = sg.make_pipeline(
  {
    shader = sg.make_shader(base_shader),
    layout = {
      attrs = {ATTR_base_pos = {format = .FLOAT3}, ATTR_base_normals_pos = {format = .FLOAT3}},
    },
    // cull_mode = .BACK,
    depth = {compare = .LESS_EQUAL, write_enabled = true},
  },
  )
  g.pip_light = sg.make_pipeline(
  {
    shader = sg.make_shader(light_shader),
    layout = {attrs = {ATTR_base_pos = {format = .FLOAT3}}, buffers = {0 = {stride = 24}}},
    // cull_mode = .BACK,
    depth = {compare = .LESS_EQUAL, write_enabled = true},
  },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.1, 0.1, 0.2, 1.0}}},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  view, projection := camera_update()
  vs_params := Vs_Params {
    view       = view,
    projection = projection,
  }
  fs_params := Fs_Params {
    objectColor = g.cube_color,
    lightColor  = g.light_color,
    lightPos    = g.light_pos,
    viewPos     = g.camera.pos,
  }

  // cube
  sg.apply_pipeline(g.pip_cube)
  sg.apply_bindings(g.bind)

  vs_params.model = linalg.matrix4_translate_f32(g.cube_pos)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.apply_uniforms(UB_fs_params, data = sg_range(&fs_params))
  sg.draw(0, 36, 1)

  // light
  sg.apply_pipeline(g.pip_light)
  sg.apply_bindings(g.bind)

  vs_params.model = linalg.matrix4_translate_f32(g.light_pos)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  // ground
  sg.apply_pipeline(g.pip_cube)
  sg.apply_bindings(g.bind)

  vs_params.model =
    linalg.matrix4_translate_f32(g.ground_pos) * linalg.matrix4_scale_f32({1000, 1, 1000})
  fs_params.objectColor = {0.2, 0.4, 0.2}
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.apply_uniforms(UB_fs_params, data = sg_range(&fs_params))
  sg.draw(0, 36, 1)

  debug_process()
  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}

@(export)
game_event :: proc(e: ^sapp.Event) {
  if e.type == .KEY_DOWN {
    if e.key_code == .R do force_reset = true
    if e.key_code == .Q do sapp.request_quit()
    if e.key_code == .T do DEBUG_TEXT = !DEBUG_TEXT
  }

  camera_process_input(e)
}
