package game

import "core:math/linalg"
import "core:math/rand"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"

CUBES_COUNT :: 1000000

Game_Memory :: struct {
  camera:    Camera,
  offscreen: Offscreen,
  display:   Display,
  inst:      [CUBES_COUNT]Sb_Instance,
}

Offscreen :: struct {
  pass:     sg.Pass,
  pipeline: sg.Pipeline,
  bindings: sg.Bindings,
}

Display :: struct {
  pass_action: sg.Pass_Action,
  pipeline:    sg.Pipeline,
  bindings:    sg.Bindings,
}

Cube :: struct {
  model: Mat4,
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  debug_init()

  color_img_desc := sg.Image_Desc {
    usage = {render_attachment = true},
    width = sapp.width(),
    height = sapp.height(),
    pixel_format = .RGBA8,
    sample_count = 1,
  }
  color_img := sg.make_image(color_img_desc)

  color_smp_desc := sg.Sampler_Desc {
    min_filter = .LINEAR,
    mag_filter = .LINEAR,
    wrap_u     = .REPEAT,
    wrap_v     = .REPEAT,
  }

  color_smp := sg.make_sampler(color_smp_desc)

  depth_img_desc := color_img_desc
  depth_img_desc.pixel_format = .DEPTH
  depth_img := sg.make_image(depth_img_desc)

  // offscreen
  g.offscreen.pass = {
    attachments = sg.make_attachments(
      {colors = {0 = {image = color_img}}, depth_stencil = {image = depth_img}},
    ),
    action = {colors = {0 = {load_action = .CLEAR, clear_value = {0.1, 0.1, 0.1, 1.0}}}},
  }

  g.offscreen.bindings.storage_buffers = {
    SBUF_vertices  = sg.make_buffer(
      {usage = {storage_buffer = true}, data = sg_range(CUBE_VERTICES)},
    ),
    SBUF_instances = sg.make_buffer(
      {
        usage = {storage_buffer = true, stream_update = true},
        size = CUBES_COUNT * size_of(Sb_Instance),
      },
    ),
  }

  g.offscreen.bindings.index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(CUBE_INDICES)},
  )

  g.offscreen.pipeline = sg.make_pipeline(
    {
      shader = sg.make_shader(offscreen_shader_desc(sg.query_backend())),
      depth = {compare = .LESS_EQUAL, write_enabled = true, pixel_format = .DEPTH},
      colors = {0 = {pixel_format = .RGBA8}},
      index_type = .UINT16,
      cull_mode = .BACK,
      sample_count = 1,
    },
  )

  // display
  g.display.pass_action = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.1, 0.1, 0.1, 1.0}}},
  }

  g.display.bindings = {
    vertex_buffers = {0 = sg.make_buffer({data = sg_range(QUAD_VERTICES)})},
    images = {0 = color_img},
    samplers = {0 = color_smp},
  }

  g.display.pipeline = sg.make_pipeline(
    {
      shader = sg.make_shader(display_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_display_a_pos = {format = .FLOAT2},
          ATTR_display_a_tex_coords = {format = .FLOAT2},
        },
      },
      depth = {compare = .LESS_EQUAL, write_enabled = true},
    },
  )

  // cubes
  for &cube in g.inst {
    cube.model =
      linalg.matrix4_translate_f32(
        {
          rand.float32_range(-2000, 2000),
          rand.float32_range(-2000, 2000),
          rand.float32_range(-2000, 2000),
        },
      ) *
      linalg.matrix4_rotate_f32(rand.float32_range(0, 360), {1, 0, 1})
  }

  sg.update_buffer(
    g.offscreen.bindings.storage_buffers[SBUF_instances],
    data = {ptr = &g.inst, size = CUBES_COUNT * size_of(Sb_Instance)},
  )
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  vs_params := Vs_Params {
    vp = projection * view,
  }

  // offscreen
  sg.begin_pass(g.offscreen.pass)
  sg.apply_pipeline(g.offscreen.pipeline)
  sg.apply_bindings(g.offscreen.bindings)

  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, CUBES_COUNT)
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
