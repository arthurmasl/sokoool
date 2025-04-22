package game

import "core:fmt"
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

  load_mesh("./assets/rigbody.glb")

  // update camera
  g.mesh.pipeline = sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_base_aPosition = {format = .FLOAT3},
          ATTR_base_aNormal = {format = .FLOAT3},
          ATTR_base_aTexCoord = {format = .FLOAT2},
          ATTR_base_aJointIndices = {format = .FLOAT4},
          ATTR_base_aWeight = {format = .FLOAT4},
        },
      },
      index_type = .UINT16,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
    },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
    depth = {load_action = .CLEAR, clear_value = 1.0},
  }

  // TODO: move to draw
  parse_animation(0, g.mesh.animation, g.mesh.skin)
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())
  now := f32(stm.sec(stm.now()))

  // parse_animation(now, g.mesh.animation, g.mesh.skin)

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  view, projection := camera_update()
  vs_params := Vs_Params {
    uModel      = linalg.matrix4_translate_f32({0, 0, 0}),
    uView       = view,
    uProjection = projection,
    uBones      = g.mesh.bones,
  }
  fs_params := Fs_Params {
    uViewPos           = g.camera.pos,
    uMaterialShininess = 0.0,
  }
  fs_dir_light := Fs_Dir_Light {
    uDirection = {0.5, -5.0, -1.5},
    uAmbient   = {0.5, 0.5, 0.5},
    uDiffuse   = {0.4, 0.4, 0.4},
    uSpecular  = {0.2, 0.2, 0.2},
  }
  fs_point_lights := Fs_Point_Lights {
    uPosition    = {{0.0, -5.0, 0.0, 1.0}},
    uAmbient     = {{0.05, 0.05, 0.05, 0.0}},
    uDiffuse     = {{0.8, 0.8, 0.8, 0.0}},
    uSpecular    = {{1.0, 1.0, 1.0, 0.0}},
    uAttenuation = {{1.0, 0.09, 0.032, 0.0}},
  }

  // mesh
  sg.apply_pipeline(g.mesh.pipeline)
  sg.apply_bindings(g.mesh.bindings)

  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.apply_uniforms(UB_fs_params, data = sg_range(&fs_params))
  sg.apply_uniforms(UB_fs_dir_light, data = sg_range(&fs_dir_light))
  sg.apply_uniforms(UB_fs_point_lights, data = sg_range(&fs_point_lights))

  sg.draw(0, g.mesh.indices_count, 1)

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
