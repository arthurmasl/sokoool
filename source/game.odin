package game

import "core:fmt"
import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"

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
  bindings:         sg.Bindings,
}

Display :: struct {
  pass_action: sg.Pass_Action,
  pipeline:    sg.Pipeline,
  bindings:    sg.Bindings,
}

create_offscreen :: proc(width, height: i32) {
  fmt.println(width, height)
  // sg.destroy_attachments(g.offscreen.attachments)
  // sg.destroy_image(g.offscreen.attachments_desc.colors[0].image)
  // sg.destroy_image(g.offscreen.attachments_desc.depth_stencil.image)

  color_img_desc := sg.Image_Desc {
    usage = {render_attachment = true},
    width = width,
    height = height,
    pixel_format = .RGBA8,
  }
  color_smp_desc := sg.Sampler_Desc {
    wrap_u     = .CLAMP_TO_EDGE,
    wrap_v     = .CLAMP_TO_EDGE,
    min_filter = .LINEAR,
    mag_filter = .LINEAR,
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

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

  create_offscreen(sapp.width(), sapp.height())

  g.offscreen.pass_action = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.1, 0.1, 0.1, 1.0}}},
  }
  g.display.pass_action = {
    colors = {0 = {load_action = .DONTCARE}},
    depth = {load_action = .DONTCARE},
    stencil = {load_action = .DONTCARE},
  }

  g.offscreen.bindings.vertex_buffers[0] = sg.make_buffer({data = sg_range(CUBE_VERTICES)})
  g.display.bindings.vertex_buffers[0] = sg.make_buffer({data = sg_range(QUAD_VERTICES)})

  g.offscreen.pipeline = sg.make_pipeline(
  {
    shader = sg.make_shader(offscreen_shader_desc(sg.query_backend())),
    layout = {attrs = {ATTR_offscreen_a_pos = {format = .FLOAT3}}},
    depth = {compare = .LESS, write_enabled = true, pixel_format = .DEPTH},
    colors = {0 = {pixel_format = .RGBA8}},
    color_count = 1,
    // primitive_type = .LINES,
  },
  )

  g.display.pipeline = sg.make_pipeline(
  {
    shader = sg.make_shader(display_shader_desc(sg.query_backend())),
    // primitive_type = .LINES,
    layout = {
      attrs = {
        ATTR_display_a_pos = {format = .FLOAT2},
        ATTR_display_a_tex_coords = {format = .FLOAT2},
      },
    },
  },
  )

}

@(export)
game_frame :: proc() {
  view, projection := camera_update()
  model := linalg.matrix4_translate_f32({-1, 1, -1})
  vs_params := Vs_Params {
    mvp = projection * view * model,
  }

  // offscreen
  sg.begin_pass({action = g.offscreen.pass_action, attachments = g.offscreen.attachments})
  sg.apply_pipeline(g.offscreen.pipeline)
  sg.apply_bindings(g.offscreen.bindings)

  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)
  sg.end_pass()

  // display
  sg.begin_pass({action = g.display.pass_action, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.display.pipeline)
  sg.apply_bindings(g.display.bindings)

  sg.draw(0, 6, 1)

  debug_process()
  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
