package game

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
    shader = sg.make_shader(base_shader_desc(sg.query_backend())),
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

}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  time := f32(stm.sec(stm.now()))

  vs_params := Base_Vs_Params {
    mvp         = projection * view,
    u_time      = time,
    u_light_dir = Vec3{0.5, 1.0, 0.5},
  }

  sg.begin_pass({action = g.passes[.Display].action, swapchain = sglue.swapchain()})
  sg.apply_pipeline(DEBUG_LINES ? g.pipelines[.Primitive] : g.pipelines[.Display])

  // cube
  sg.apply_bindings(g.bindings[.Cube])
  sg.apply_uniforms(UB_base_vs_params, data = sg_range(&vs_params))
  sg.draw(g.ranges[.Cube].base_element, g.ranges[.Cube].num_elements, 1)

  // terrain
  sg.apply_bindings(g.bindings[.Terrain])
  sg.apply_uniforms(UB_base_vs_params, data = sg_range(&vs_params))
  sg.draw(g.ranges[.Terrain].base_element, g.ranges[.Terrain].num_elements, 1)

  debug_process()

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
