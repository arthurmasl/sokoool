package game

import "core:image/png"
import "core:log"
import "core:slice"

import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

  // vertex buffer
  vertices := [?]Vertex {
    {pos = {0.5, 0.5, 0.0}, color = {1.0, 0.0, 0.0, 1.0}, uvs = {1.0, 1.0}},
    {pos = {0.5, -0.5, 0.0}, color = {0.0, 1.0, 0.0, 1.0}, uvs = {1.0, 0.0}},
    {pos = {-0.5, -0.5, 0.0}, color = {0.0, 0.0, 1.0, 1.0}, uvs = {0.0, 0.0}},
    {pos = {-0.5, 0.5, 0.0}, color = {1.0, 1.0, 0.0, 1.0}, uvs = {0.0, 1.0}},
  }
  g.bind.vertex_buffers[0] = sg.make_buffer(
    {data = {ptr = &vertices, size = size_of(vertices)}},
  )

  // index buffer
  indices := [?]u16{0, 1, 3, 1, 2, 3}
  g.bind.index_buffer = sg.make_buffer(
    {type = .INDEXBUFFER, data = {ptr = &indices, size = size_of(indices)}},
  )

  // load image
  img_data, img_data_ok := read_entire_file("assets/round_cat.png", context.temp_allocator)
  if !img_data_ok {
    log.error("Failed loading texture")
    return
  }

  img, img_err := png.load_from_bytes(img_data, nil, context.temp_allocator)
  if img_err != nil {
    log.error(img_err)
    return
  }

  // texture
  g.bind.images[IMG_tex] = sg.make_image(
    {
      width = i32(img.width),
      height = i32(img.height),
      data = {
        subimage = {
          0 = {
            0 = {ptr = raw_data(img.pixels.buf), size = uint(slice.size(img.pixels.buf[:]))},
          },
        },
      },
    },
  )

  // sampler
  g.bind.samplers[SMP_smp] = sg.make_sampler({})

  // pipeline
  g.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(simple_shader_desc(sg.query_backend())),
      index_type = .UINT16,
      cull_mode = .BACK,
      // primitive_type = .LINES,
      layout = {
        attrs = {
          ATTR_simple_pos = {format = .FLOAT3},
          ATTR_simple_color0 = {format = .FLOAT4},
          ATTR_simple_uvs0 = {format = .FLOAT2},
        },
      },
    },
  )

  // clear
  g.pass_action = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
  }
}

@(export)
game_frame :: proc() {
  sg.begin_pass({action = g.pass_action, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.pip)
  sg.apply_bindings(g.bind)

  sg.draw(0, 6, 1)
  sg.end_pass()
  sg.commit()
}

@(export)
game_event :: proc(e: ^sapp.Event) {
  if e.type == .KEY_DOWN {
    if e.key_code == .R do force_reset = true
    if e.key_code == .Q do sapp.request_quit()
  }
}
