package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import sshape "sokol/shape"
import stm "sokol/time"

Game_Memory :: struct {
  camera:     Camera,
  pass:       sg.Pass_Action,
  display:    Entity,
  debug_pip:  sg.Pipeline,
  draw_plane: sshape.Element_Range,
  draw_quad:  sshape.Element_Range,
}

@(export)
game_init :: proc() {
  if g == nil {
    g = new(Game_Memory)
    game_hot_reloaded(g)
    camera_init()
  }

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  vertices: [6 * 10 * 1024]f32
  indices: [16 * 8 * 1024]u16

  buf := sshape.Buffer {
    vertices = {buffer = {ptr = &vertices, size = size_of(vertices)}},
    indices = {buffer = {ptr = &indices, size = size_of(indices)}},
  }
  buf = sshape.build_plane(buf, {width = 2048.0, depth = 2048.0, tiles = 100})
  g.draw_plane = sshape.element_range(buf)
  // buf = sshape.build_box(
  //   buf,
  //   {width = 1.0, depth = 1.0, height = 1.0, tiles = 1, merge = true, random_colors = true},
  // )
  // buf = sshape.build_cylinder(
  //   buf,
  //   {radius = 2.0, height = 1.0, slices = 100, stacks = 1, merge = true, random_colors = true},
  // )
  // buf = sshape.build_sphere(buf, {radius = 3, slices = 50, stacks = 15, random_colors = true})

  buf = sshape.build_plane(buf, {width = 100.0, depth = 100.0, tiles = 1})
  g.draw_quad = sshape.element_range(buf)

  g.display.bind.vertex_buffers[0] = sg.make_buffer(sshape.vertex_buffer_desc(buf))
  g.display.bind.index_buffer = sg.make_buffer(sshape.index_buffer_desc(buf))

  pipeline_desc := sg.Pipeline_Desc {
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
    cull_mode = .NONE,
    depth = {compare = .LESS_EQUAL, write_enabled = true},
    // primitive_type = .LINE_STRIP,
    // colors = {
    //   0 = {
    //     blend = {
    //       enabled = true,
    //       src_factor_rgb = .SRC_ALPHA,
    //       dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
    //       op_rgb = .ADD,
    //       src_factor_alpha = .SRC_ALPHA,
    //       dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
    //       op_alpha = .ADD,
    //     },
    //   },
    // },
    // color_count = 1,
  }

  // g.display.bind.images[IMG_heightmap_texture] = sg.make_image(load_image("hm/height_map.png"))
  // g.display.bind.samplers[SMP_heightmap_smp] = sg.make_sampler({wrap_u = .CLAMP_TO_EDGE})

  // g.display.bind.images[IMG_diffuse_texture] = sg.make_image(load_image("hm/diffuse.png"))
  // g.display.bind.samplers[SMP_diffuse_smp] = sg.make_sampler({wrap_u = .CLAMP_TO_EDGE})

  g.display.pip = sg.make_pipeline(pipeline_desc)

  debug_pip_desc := pipeline_desc
  debug_pip_desc.primitive_type = .LINE_STRIP
  g.debug_pip = sg.make_pipeline(debug_pip_desc)

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  time := f32(stm.sec(stm.now()))
  model :=
    linalg.matrix4_translate_f32({0, -500, 0}) *
    linalg.matrix4_rotate_f32(linalg.RAD_PER_DEG, {0, 1, 0})

  vs_params := Vs_Params {
    mvp         = projection * view * model,
    u_time      = time,
    u_light_dir = Vec3{0, 1, 0},
  }

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  // cube
  sg.apply_pipeline(DEBUG_LINES ? g.debug_pip : g.display.pip)
  sg.apply_bindings(g.display.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(g.draw_plane.base_element, g.draw_plane.num_elements, 1)

  debug_process()

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
