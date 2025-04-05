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
  sapp.show_mouse(false)

  g.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(CUBE_VERTICES)})
  g.bind.index_buffer = sg.make_buffer({type = .INDEXBUFFER, data = sg_range(CUBE_INDICES)})

  img := load_image("assets/round_cat.png")
  g.bind.samplers[SMP_smp] = sg.make_sampler({})
  g.bind.images[IMG_tex] = sg.make_image(
    {
      width = i32(img.width),
      height = i32(img.height),
      data = {subimage = {0 = {0 = sg_range(img)}}},
    },
  )

  g.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(simple_shader_desc(sg.query_backend())),
      layout = {
        attrs = {ATTR_simple_pos = {format = .FLOAT3}, ATTR_simple_uvs0 = {format = .FLOAT2}},
      },
      index_type = .UINT16,
      cull_mode = .BACK,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
      // primitive_type = .LINES,
    },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
  }
}

cubes_pos :: [?]Vec3 {
  {1, 0, 0},
  {5, 0, 2},
  {0, 5, 2},
  {1, -3, 8},
  {0, 9, 3},
  {5, 2, 8},
  {-5, 0, 5},
  {-5, 2, -3},
  {4, 1, -7},
}

@(export)
game_frame :: proc() {
  g.delta_time = stm.laptime(&g.last_time)

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.pip)
  sg.apply_bindings(g.bind)

  view, projection := camera_update()
  vs_params := Vs_Params{{view = view, projection = projection}}

  for pos in cubes_pos {
    vs_params.model =
      linalg.matrix4_translate_f32(pos) *
      linalg.matrix4_rotate_f32(linalg.RAD_PER_DEG * -65 * f32(stm.sec(stm.now())), pos)

    sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))

    sg.draw(0, 36, 1)
  }

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}

SPEED :: 20
SENSITIVITY :: 0.005

@(export)
game_event :: proc(e: ^sapp.Event) {
  if e.type == .KEY_DOWN {
    if e.key_code == .R do force_reset = true
    if e.key_code == .Q do sapp.request_quit()

    camera_key_down(e)
  }

  if e.type == .MOUSE_MOVE {
    camera_mouse_move(e)
  }
}
