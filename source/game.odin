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
  attachments_desc: sg.Attachment_Desc,
  pass_action:      sg.Pass_Action,
  pipeline:         sg.Pipeline,
  bindings_cube:    sg.Bindings,
}

Display :: struct {
  pass_action: sg.Pass_Action,
  pipeline:    sg.Pipeline,
  bindings:    sg.Bindings,
}

create_offscreen :: proc() {
  color_img_desc := sg.Image_Desc {
    usage = {render_attachment = true},
    width = sapp.width(),
    height = sapp.height(),
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

  g.offscreen.attachments = sg.make_attachments(
    {colors = {0 = {image = color_img}}, depth_stencil = {image = depth_img}},
  )

  g.display.bindings.images[IMG__diffuse_map] = color_img
  g.display.bindings.samplers[IMG_diffuse_smp] = color_smp
}

create_display :: proc() {

}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  create_offscreen()

  g.offscreen.pass_action = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
  g.display.pass_action = {
    colors = {0 = {load_action = .DONTCARE}},
    depth = {load_action = .DONTCARE},
    stencil = {load_action = .DONTCARE},
  }

  
  // odinfmt: disable
  cube_vertices := [?]f32{
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
  quad_vertices := [?]f32 {
        // positions   // texCoords
        -1.0,  1.0,  0.0, 1.0,
        -1.0, -1.0,  0.0, 0.0,
         1.0, -1.0,  1.0, 0.0,

        -1.0,  1.0,  0.0, 1.0,
         1.0, -1.0,  1.0, 0.0,
         1.0,  1.0,  1.0, 1.0,
  }
  // odinfmt: enable

  cube_buffer := sg.make_buffer({data = {ptr = &cube_vertices, size = size_of(cube_vertices)}})
  quad_buffer := sg.make_buffer({data = {ptr = &quad_vertices, size = size_of(quad_vertices)}})

  g.offscreen.bindings_cube.vertex_buffers[0] = cube_buffer
  g.display.bindings.vertex_buffers[0] = quad_buffer

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
