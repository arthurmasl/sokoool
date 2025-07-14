package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import sshape "sokol/shape"
import stm "sokol/time"

Game_Memory :: struct {
  camera:  Camera,
  pass:    sg.Pass_Action,
  display: Entity,
  draw:    sshape.Element_Range,
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  vertices: [6 * 1024]f32
  indices: [16 * 1024]u16

  buf := sshape.Buffer {
    vertices = {buffer = {ptr = &vertices, size = size_of(vertices)}},
    indices = {buffer = {ptr = &indices, size = size_of(indices)}},
  }
  buf = sshape.build_plane(buf, {width = 3.0, depth = 3.0, tiles = 30, random_colors = true})

  g.draw = sshape.element_range(buf)

  g.display.bind.vertex_buffers[0] = sg.make_buffer(sshape.vertex_buffer_desc(buf))
  g.display.bind.index_buffer = sg.make_buffer(sshape.index_buffer_desc(buf))

  g.display.pip = sg.make_pipeline(
  {
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
    // primitive_type = .LINES,
  },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  model :=
    linalg.matrix4_translate_f32({0, 0.5, 0}) *
    linalg.matrix4_rotate_f32(linalg.RAD_PER_DEG * 90, {0, 1, 0})
  vs_params := Vs_Params {
    mvp    = projection * view * model,
    u_time = f32(stm.sec(stm.now())),
  }

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  // cube
  sg.apply_pipeline(g.display.pip)
  sg.apply_bindings(g.display.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(g.draw.base_element, g.draw.num_elements, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
