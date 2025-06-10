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

light_pos := Vec3{1.5, 3.0, 25.5}

load_diffuse :: proc() {
  img_data, img_data_ok := read_entire_file("assets/bricks2.jpg", context.temp_allocator)
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
  img_data, img_data_ok := read_entire_file("assets/bricks2_normal.jpg", context.temp_allocator)
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

load_depth :: proc() {
  img_data, img_data_ok := read_entire_file("assets/bricks2_disp.jpg", context.temp_allocator)
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

  g.cube.bind.images[IMG__depth_map] = sg.make_image(
    {
      width = i32(width),
      height = i32(height),
      pixel_format = .RGBA8,
      data = {subimage = {0 = {0 = {ptr = pixels, size = uint(width * height * 4)}}}},
    },
  )

  g.cube.bind.samplers[SMP_depth_smp] = sg.make_sampler({})
}

compute_tangent :: proc(pos0, pos1, pos2: Vec3, uv0, uv1, uv2: Vec2) -> Vec3 {
  edge0 := pos1 - pos0
  edge1 := pos2 - pos0
  delta_uv0 := uv1 - uv0
  delta_uv1 := uv2 - uv0

  f := 1.0 / (delta_uv0.x * delta_uv1.y - delta_uv1.x * delta_uv0.y)

  x := f * (delta_uv1.y * edge0.x - delta_uv0.y * edge1.x)
  y := f * (delta_uv1.y * edge0.y - delta_uv0.y * edge1.y)
  z := f * (delta_uv1.y * edge0.z - delta_uv0.y * edge1.z)

  return Vec3{x, y, z}
}

create_cube :: proc() {
  // buffers
  pos0 := Vec3{-1, 1, 0}
  pos1 := Vec3{-1, -1, 0}
  pos2 := Vec3{1, -1, 0}
  pos3 := Vec3{1, 1, 0}

  nm := Vec3{0, 0, 1}

  uv0 := Vec2{0, 1}
  uv1 := Vec2{0, 0}
  uv2 := Vec2{1, 0}
  uv3 := Vec2{1, 1}

  ta0 := compute_tangent(pos0, pos1, pos2, uv0, uv1, uv2)
  ta1 := compute_tangent(pos0, pos2, pos3, uv0, uv2, uv3)

  vertices := []struct {
    pos:       Vec3,
    normal:    Vec3,
    texcoords: Vec2,
    tangent:   Vec3,
  } {
    {pos = pos0, normal = nm, texcoords = uv0, tangent = ta0},
    {pos = pos1, normal = nm, texcoords = uv1, tangent = ta0},
    {pos = pos2, normal = nm, texcoords = uv2, tangent = ta0},
    //
    {pos = pos0, normal = nm, texcoords = uv0, tangent = ta1},
    {pos = pos2, normal = nm, texcoords = uv2, tangent = ta1},
    {pos = pos3, normal = nm, texcoords = uv3, tangent = ta1},
  }

  g.cube.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})

  load_diffuse()
  load_normal()
  load_depth()

  // pipeline
  g.cube.pip = sg.make_pipeline(
  {
    shader = sg.make_shader(base_shader_desc(sg.query_backend())),
    layout = {
      attrs = {
        ATTR_base_a_pos = {format = .FLOAT3},
        ATTR_base_a_normal = {format = .FLOAT3},
        ATTR_base_a_tex_coords = {format = .FLOAT2},
        ATTR_base_a_tangent = {format = .FLOAT3},
      },
    },
    depth = {compare = .LESS_EQUAL, write_enabled = true},
    // index_type = .UINT16,
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
    view_pos   = g.camera.pos,
    light_pos  = light_pos,
  }
  vs_params.model = linalg.matrix4_translate_f32({0, 1, -5}) * linalg.matrix4_scale_f32({6, 6, 1})

  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))

  sg.draw(0, 6, 1)

  vs_params.model = linalg.matrix4_translate_f32(light_pos)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 6, 1)

  debug_process()
  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
