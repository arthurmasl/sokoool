package game

import "core:fmt"
import "core:image/png"
import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"
import stbi "vendor:stb/image"

Entity :: struct {
  pip:  sg.Pipeline,
  bind: sg.Bindings,
}

Game_Memory :: struct {
  camera: Camera,
  pass:   sg.Pass_Action,
  cube:   Entity,
  skybox: Entity,
}

create_cube :: proc() {
  // vertex 
  g.cube.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(CUBE_NORMALS_UVS_VERTICES)})

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
      depth = {compare = .LESS, write_enabled = true},
    },
  )
}

create_skybox :: proc() {
  // vertex 
  g.skybox.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(CUBE_NORMAL_VERTICES)})

  // texture
  image_data: sg.Image_Data
  skybox_names := [?]string {
    "skybox_right",
    "skybox_left",
    "skybox_top",
    "skybox_bottom",
    "skybox_front",
    "skybox_back",
  }

  // load images
  pixels_arr: [len(skybox_names)][^]byte

  for name, i in skybox_names {
    path := fmt.tprintf("assets/skybox/%s.jpg", name)
    img_data, img_data_ok := read_entire_file(path, context.temp_allocator)
    if !img_data_ok {
      fmt.println("Failed loading texture")
      return
    }

    desired_channels := i32(4)
    width, height, channels: i32
    pixels := stbi.load_from_memory(
      &img_data[0],
      i32(len(img_data)),
      &width,
      &height,
      &channels,
      desired_channels,
    )
    if pixels == nil {
      fmt.println("Failed to load texture")
      return
    }
    pixels_arr[i] = pixels

    image_data.subimage[i][0] = {
      ptr  = pixels,
      size = uint(width * height * desired_channels),
    }
  }

  for pixels in pixels_arr {
    stbi.image_free(pixels)
  }

  g.skybox.bind.images[IMG__skybox_texture] = sg.make_image(
    {type = .CUBE, pixel_format = .RGBA8, width = 2048, height = 2048, data = image_data},
  )

  // sampler
  g.skybox.bind.samplers[SMP_skybox_texture_smp] = sg.make_sampler({})

  // pipeline
  g.skybox.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(skybox_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_skybox_a_pos = {format = .FLOAT3},
          ATTR_skybox_a_normals_pos = {format = .FLOAT3},
        },
      },
      depth = {compare = .LESS_EQUAL, write_enabled = true},
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
  create_skybox()

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
    // depth = {load_action = .CLEAR, clear_value = 1.0},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())
  // now := f32(stm.sec(stm.now()))

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  view, projection := camera_update()
  vs_params := Vs_Params {
    view       = view,
    projection = projection,
  }

  // cube
  vs_params.model = linalg.matrix4_translate_f32({-1, 1, -1}) * linalg.matrix4_scale_f32({3, 3, 3})
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  vs_params.model = linalg.matrix4_translate_f32({3, 0, 0})
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  vs_params.model =
    linalg.matrix4_translate_f32({0, -1, 0}) * linalg.matrix4_scale_f32({200, 1, 200})
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  // skybox
  vs_params.view[3][0] = 0.0
  vs_params.view[3][1] = 0.0
  vs_params.view[3][2] = 0.0

  sg.apply_pipeline(g.skybox.pip)
  sg.apply_bindings(g.skybox.bind)
  sg.apply_uniforms(UB_vs_skybox_params, data = sg_range(&vs_params))
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
