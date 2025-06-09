package game

import "core:fmt"
import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"
import stbi "vendor:stb/image"

Game_Memory :: struct {
  camera: Camera,
  pass:   sg.Pass_Action,
  cube:   Entity,
}

light_pos := Vec3{1.5, 3.0, 5.5}

load_diffuse :: proc() {
  img_data, img_data_ok := read_entire_file("assets/brickwall.jpg", context.temp_allocator)
  if !img_data_ok {
    fmt.println("Failed loading texture")
    return
  }

  width, height, channels: i32
  pixels := stbi.load_from_memory(&img_data[0], i32(len(img_data)), &width, &height, &channels, 4)
  if pixels == nil {
    fmt.println("Failed to load texture")
    return
  }
  defer stbi.image_free(pixels)

  g.cube.bind.images[IMG__diffuse_map] = sg.make_image(
    {
      width = i32(width),
      height = i32(height),
      pixel_format = .RGBA8,
      data = {subimage = {0 = {0 = {ptr = pixels, size = uint(width * height * 4)}}}},
    },
  )

  g.cube.bind.samplers[SMP_diffuse_smp] = sg.make_sampler({})

}

load_normal :: proc() {
  img_data, img_data_ok := read_entire_file("assets/brickwall_normal.jpg", context.temp_allocator)
  if !img_data_ok {
    fmt.println("Failed loading texture")
    return
  }

  width, height, channels: i32
  pixels := stbi.load_from_memory(&img_data[0], i32(len(img_data)), &width, &height, &channels, 4)
  if pixels == nil {
    fmt.println("Failed to load texture")
    return
  }
  defer stbi.image_free(pixels)

  g.cube.bind.images[IMG__normal_map] = sg.make_image(
    {
      width = i32(width),
      height = i32(height),
      pixel_format = .RGBA8,
      data = {subimage = {0 = {0 = {ptr = pixels, size = uint(width * height * 4)}}}},
    },
  )

  g.cube.bind.samplers[SMP_normal_smp] = sg.make_sampler({})

}

create_cube :: proc() {
  // buffers
  vertices := []struct {
    pos:       Vec3,
    normal:    Vec3,
    texcoords: Vec2,
  } {
    {pos = {-0.5, -0.5, 0.5}, normal = {0, 0, 1}, texcoords = {1, 1}},
    {pos = {0.5, -0.5, 0.5}, normal = {0, 0, 1}, texcoords = {0, 1}},
    {pos = {0.5, 0.5, 0.5}, normal = {0, 0, 1}, texcoords = {0, 0}},
    {pos = {-0.5, 0.5, 0.5}, normal = {0, 0, 1}, texcoords = {1, 0}},
  }
  indieces := []u16{0, 1, 2, 0, 2, 3}

  g.cube.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})

  g.cube.bind.index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(indieces)},
  )

  load_diffuse()
  load_normal()

  // pipeline
  g.cube.pip = sg.make_pipeline(
  {
    shader = sg.make_shader(base_shader_desc(sg.query_backend())),
    layout = {
      attrs = {
        ATTR_base_a_pos = {format = .FLOAT3},
        ATTR_base_a_normal = {format = .FLOAT3},
        ATTR_base_a_tex_coords = {format = .FLOAT2},
      },
    },
    depth = {compare = .LESS_EQUAL, write_enabled = true},
    index_type = .UINT16,
    // cull_mode = .BACK,
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
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)

  view, projection := camera_update()
  vs_params := Vs_Params {
    view       = view,
    projection = projection,
  }
  vs_params.model = linalg.matrix4_translate_f32({0, 1, -5}) * linalg.matrix4_scale_f32({6, 6, 1})

  fs_params := Fs_Params {
    view_pos      = g.camera.pos,
    light_pos     = light_pos,
    enable_normal = 1.0,
  }

  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.apply_uniforms(UB_fs_params, data = sg_range(&fs_params))

  sg.draw(0, 6, 1)

  vs_params.model = linalg.matrix4_translate_f32(light_pos)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 6, 1)

  debug_process()
  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
