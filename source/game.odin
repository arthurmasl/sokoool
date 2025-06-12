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
  camera:    Camera,
  offscreen: Offscreen,
  display:   Display,
}

Offscreen :: struct {
  attachments:      sg.Attachments,
  attachments_desc: sg.Attachments_Desc,
  pass_action:      sg.Pass_Action,
  pipeline:         sg.Pipeline,
  bindings_cube:    sg.Bindings,
}

Display :: struct {
  pass_action: sg.Pass_Action,
  pipeline:    sg.Pipeline,
  bindings:    sg.Bindings,
}

create_offscreen :: proc(width, height: i32) {
  sg.destroy_attachments(g.offscreen.attachments)
  sg.destroy_image(g.offscreen.attachments_desc.colors[0].image)
  sg.destroy_image(g.offscreen.attachments_desc.depth_stencil.image)

  color_img_desc := sg.Image_Desc {
    usage = {render_attachment = true},
    width = width,
    height = height,
    pixel_format = .RGBA8,
  }
  color_smp_desc := sg.Sampler_Desc {
    min_filter = .LINEAR,
    mag_filter = .LINEAR,
    wrap_u     = .CLAMP_TO_EDGE,
    wrap_v     = .CLAMP_TO_EDGE,
    compare    = .NEVER,
  }

  color_img := sg.make_image(color_img_desc)
  color_smp := sg.make_sampler(color_smp_desc)

  depth_img_desc := color_img_desc
  depth_img_desc.pixel_format = .DEPTH
  depth_img := sg.make_image(depth_img_desc)

  g.offscreen.attachments_desc = {
    colors = {0 = {image = color_img}},
    depth_stencil = {image = depth_img},
  }
  g.offscreen.attachments = sg.make_attachments(g.offscreen.attachments_desc)

  g.display.bindings.images[0] = color_img
  g.display.bindings.samplers[0] = color_smp
}

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

  g.offscreen.bindings_cube.images[0] = sg.make_image(
    {
      width = i32(width),
      height = i32(height),
      pixel_format = .RGBA8,
      data = {subimage = {0 = {0 = {ptr = pixels, size = uint(width * height * 4)}}}},
    },
  )

  // g.offscreen.bindings_cube.samplers[0] = g.display.bindings.samplers[0]
  g.offscreen.bindings_cube.samplers[0] = sg.make_sampler({})
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  create_offscreen(sapp.width(), sapp.height())

  g.offscreen.pass_action = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
  g.display.pass_action = {
    colors = {0 = {load_action = .DONTCARE}},
    depth = {load_action = .DONTCARE},
    stencil = {load_action = .DONTCARE},
  }

  
  // odinfmt: disable
  cube_vertices := []f32{
       // positions          // texture Coords
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
  }
  quad_vertices := []f32 {
        // positions   // texCoords
        -1.0,  1.0,  0.0, 1.0,
        -1.0, -1.0,  0.0, 0.0,
         1.0, -1.0,  1.0, 0.0,

        -1.0,  1.0,  0.0, 1.0,
         1.0, -1.0,  1.0, 0.0,
         1.0,  1.0,  1.0, 1.0,
  }
  // odinfmt: enable

  cube_buffer := sg.make_buffer(
    {data = {ptr = raw_data(cube_vertices), size = size_of(cube_vertices)}},
  )
  quad_buffer := sg.make_buffer(
    {data = {ptr = raw_data(quad_vertices), size = size_of(quad_vertices)}},
  )

  g.offscreen.bindings_cube.vertex_buffers[0] = cube_buffer
  g.display.bindings.vertex_buffers[0] = quad_buffer

  g.offscreen.pipeline = sg.make_pipeline(
    {
      shader = sg.make_shader(offscreen_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_offscreen_a_pos = {format = .FLOAT3},
          ATTR_offscreen_a_tex_coords = {format = .FLOAT2},
        },
      },
      depth = {compare = .LESS, write_enabled = true, pixel_format = .DEPTH},
      colors = {0 = {pixel_format = .RGBA8}},
      color_count = 1,
    },
  )

  g.display.pipeline = sg.make_pipeline(
    {
      shader = sg.make_shader(display_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_offscreen_a_pos = {format = .FLOAT2},
          ATTR_offscreen_a_tex_coords = {format = .FLOAT2},
        },
      },
    },
  )

  load_diffuse()

}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  // offscreen
  sg.begin_pass({action = g.offscreen.pass_action, attachments = g.offscreen.attachments})
  sg.apply_pipeline(g.offscreen.pipeline)
  sg.apply_bindings(g.offscreen.bindings_cube)

  view, projection := camera_update()
  vs_params := Vs_Params {
    view       = view,
    projection = projection,
  }

  vs_params.model = linalg.matrix4_translate_f32({0, 1, 0}) * linalg.matrix4_scale_f32({6, 6, 1})
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)
  sg.end_pass()

  // display
  sg.begin_pass({action = g.display.pass_action, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.display.pipeline)
  sg.apply_bindings(g.display.bindings)

  fs_params := Fs_Params {
    offset = Vec2{2.0 / sapp.widthf(), 2.0 / sapp.heightf()},
  }
  sg.apply_uniforms(UB_fs_params, data = sg_range(&fs_params))
  sg.draw(0, 6, 1)

  debug_process()
  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
