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

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  load_object("./assets/rigbody.glb")

  // update camera
  g.mesh.pipeline = sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_base_position = {format = .FLOAT3},
          ATTR_base_normal = {format = .FLOAT3},
          ATTR_base_texcoord = {format = .FLOAT2},
        },
      },
      index_type = .UINT16,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
    },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
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
  vs_params.model = linalg.matrix4_translate_f32({0, -4, 0})

  // mesh
  sg.apply_pipeline(g.mesh.pipeline)
  sg.apply_bindings(g.mesh.bindings)

  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))

  sg.draw(0, g.mesh.face_count, 1)

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
