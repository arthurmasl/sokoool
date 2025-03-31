package game

import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  shader := sg.make_shader(triangle_shader_desc(sg.query_backend()))

  // vertex buffer
  vertices := [?]f32{0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0}
  g.bind.vertex_buffers[0] = sg.make_buffer(
    {data = {ptr = &vertices, size = size_of(vertices)}},
  )

  // index buffer
  indices := [?]u16{0, 1, 2, 0, 2, 3}
  g.bind.index_buffer = sg.make_buffer(
    {type = .INDEXBUFFER, data = {ptr = &indices, size = size_of(indices)}},
  )

  // pipeline
  g.pip = sg.make_pipeline(
    {
      shader = shader,
      index_type = .UINT16,
      layout = {attrs = {ATTR_triangle_position = {format = .FLOAT3}}},
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
