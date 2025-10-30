package game

import "core:fmt"
import "core:image"
import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import sshape "sokol/shape"
import stm "sokol/time"

Game_Memory :: struct {
  camera:    Camera,
  //
  ranges:    [BindingID]sshape.Element_Range,
  passes:    [PassID]sg.Pass,
  bindings:  [BindingID]sg.Bindings,
  pipelines: [PipelineID]sg.Pipeline,
}

@(export)
game_init :: proc() {
  if g == nil {
    g = new(Game_Memory)
    game_hot_reloaded(g)
    camera_init()
  }

  read_config()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  // passes
  g.passes[.Display] = {
    action = {colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}}},
  }

  // resources
  default_pip_desc := sg.Pipeline_Desc {
    shader = sg.make_shader(display_shader_desc(sg.query_backend())),
    layout = {
      buffers = {0 = sshape.vertex_buffer_layout_state()},
      attrs = {
        0 = sshape.position_vertex_attr_state(),
        1 = sshape.normal_vertex_attr_state(),
        2 = sshape.texcoord_vertex_attr_state(),
        3 = sshape.color_vertex_attr_state(),
      },
    },
    index_type = .UINT16,
    cull_mode = .BACK,
    depth = {compare = .LESS_EQUAL, write_enabled = true},
  }

  // primitive
  debug_pip_desc := default_pip_desc
  debug_pip_desc.primitive_type = .LINE_STRIP
  g.pipelines[.Primitive] = sg.make_pipeline(debug_pip_desc)

  // terrain
  g.pipelines[.Display] = sg.make_pipeline(default_pip_desc)
  build_shape(
    .Terrain,
    sshape.Plane {
      width = 200,
      depth = 200,
      tiles = 1,
      color = sshape.color_3f(0.1, 0.5, 0.2),
    },
  )

  // cube
  g.pipelines[.Display] = sg.make_pipeline(default_pip_desc)
  cube_model := transmute([4][4]f32)(linalg.matrix4_translate_f32({0, 1.5, 0}))
  build_shape(
    .Cube,
    sshape.Box {
      width = 3,
      height = 3,
      depth = 3,
      tiles = 1,
      color = sshape.color_3f(0.5, 0.8, 0.2),
      transform = {m = cube_model},
    },
  )

  // shadow
  shadow_map_img := sg.make_image(
    {
      usage = {depth_stencil_attachment = true},
      width = 2048,
      height = 2048,
      pixel_format = .DEPTH,
      sample_count = 1,
    },
  )

  shadow_map_ds_view := sg.make_view(
    {depth_stencil_attachment = {image = shadow_map_img}},
  )
  shadow_map_tex_view := sg.make_view({texture = {image = shadow_map_img}})

  g.passes[.Shadow] = {
    action = {depth = {load_action = .CLEAR, store_action = .STORE, clear_value = 1.0}},
    attachments = {depth_stencil = shadow_map_ds_view},
  }

  shadow_sampler := sg.make_sampler(
    {
      min_filter = .LINEAR,
      mag_filter = .LINEAR,
      wrap_u = .CLAMP_TO_EDGE,
      wrap_v = .CLAMP_TO_EDGE,
      compare = .LESS,
    },
  )

  g.pipelines[.Shadow] = sg.make_pipeline(
    {
      layout = {
        buffers = {0 = {stride = 6 * size_of(f32)}},
        // attrs = {ATTR_shadow_pos = {format = .FLOAT3}},
        attrs = {0 = {format = .FLOAT3}},
      },
      shader = sg.make_shader(shadow_shader_desc(sg.query_backend())),
      index_type = .UINT16,
      cull_mode = .FRONT,
      sample_count = 1,
      depth = {pixel_format = .DEPTH, compare = .LESS_EQUAL, write_enabled = true},
      colors = {0 = {pixel_format = .NONE}},
    },
  )

  g.bindings[.Shadow] = {
    vertex_buffers = {0 = g.bindings[.Cube].vertex_buffers[0]},
    index_buffer = g.bindings[.Cube].index_buffer,
  }

  g.bindings[.Cube].views[0] = shadow_map_tex_view
  g.bindings[.Cube].samplers[0] = shadow_sampler

  g.bindings[.Terrain].views[0] = shadow_map_tex_view
  g.bindings[.Terrain].samplers[0] = shadow_sampler
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()

  eye_pos := g.camera.pos

  light_pos := Vec4{50, 50, -50, 1.0}
  light_view := linalg.matrix4_look_at_f32(light_pos.xyz, {0, 1.5, 0}, {0, 1, 0})
  light_proj := linalg.matrix_ortho3d_f32(-5, 5, -5, 5, 0, 100)
  light_view_proj := light_view * light_proj

  vs_params := Display_Vs_Params {
    mvp       = projection * view,
    model     = {},
    light_mvp = light_view_proj,
  }

  fs_params := Display_Fs_Params {
    light_dir = light_pos.xyz,
    eye_pos   = eye_pos,
  }

  sg.begin_pass({action = g.passes[.Display].action, swapchain = sglue.swapchain()})
  sg.apply_pipeline(DEBUG_LINES ? g.pipelines[.Primitive] : g.pipelines[.Display])
  sg.apply_uniforms(UB_display_fs_params, sg_range(&fs_params))

  // cube
  sg.apply_bindings(g.bindings[.Cube])
  sg.apply_uniforms(UB_display_vs_params, data = sg_range(&vs_params))
  sg.draw(g.ranges[.Cube].base_element, g.ranges[.Cube].num_elements, 1)

  // terrain
  sg.apply_bindings(g.bindings[.Terrain])
  sg.apply_uniforms(UB_display_vs_params, data = sg_range(&vs_params))
  sg.draw(g.ranges[.Terrain].base_element, g.ranges[.Terrain].num_elements, 1)

  debug_process()

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
