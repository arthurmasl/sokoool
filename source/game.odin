package game

import "core:fmt"
import "core:image/png"
import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

Game_Memory :: struct {
  camera: Camera,
  pass:   sg.Pass_Action,
  cube:   Entity,
}

create_cube :: proc() {
  // buffers
  g.cube.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(CUBE_NORMAL_VERTICES)})
  g.cube.bind.index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(CUBE_INDICES)},
  )

  // load image
  img_data, img_data_ok := read_entire_file("assets/round_cat.png", context.temp_allocator)
  if !img_data_ok {
    fmt.println("Failed loading texture")
    return
  }

  img, img_err := png.load_from_bytes(img_data, nil, context.temp_allocator)
  if img_err != nil {
    fmt.println(img_err)
    return
  }

  // texture
  g.cube.bind.images[IMG__diffuse_texture] = sg.make_image(
    {
      width = i32(img.width),
      height = i32(img.height),
      data = {subimage = {0 = {0 = sg_range(img)}}},
    },
  )

  // sampler
  g.cube.bind.samplers[SMP_diffuse_texture_smp] = sg.make_sampler({})

  // pipeline
  g.cube.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_base_a_pos = {format = .FLOAT3},
          ATTR_base_a_normals_pos = {format = .FLOAT3},
          ATTR_base_a_tex_coords = {format = .FLOAT2},
        },
      },
      index_type = .UINT16,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
      cull_mode = .BACK,
    },
  )
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()
  create_cube()

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
  vs_params.model = linalg.matrix4_translate_f32({-1, 1, -1})

  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  debug_process()
  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
