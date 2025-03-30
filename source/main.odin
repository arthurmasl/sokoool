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

  vertices := [?]Vertex {
    {pos = {0.0, 0.5, 0.5}, color = {1, 0, 0, 1}},
    {pos = {0.8, -0.5, 0.5}, color = {0, 1, 0, 1}},
    {pos = {-0.8, -0.5, 0.5}, color = {0, 0, 1, 1}},
  }

  g.bind.vertex_buffers[0] = sg.make_buffer(
    {data = {ptr = &vertices, size = size_of(vertices)}},
  )

  g.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(triangle_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_triangle_position = {format = .FLOAT3},
          ATTR_triangle_color0 = {format = .FLOAT4},
        },
      },
    },
  )

  g.pass_action = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
  }

}

@(export)
game_frame :: proc() {
  sg.begin_pass({action = g.pass_action, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.pip)
  sg.apply_bindings(g.bind)

  sg.draw(0, 3, 1)
  sg.end_pass()
  sg.commit()
}

@(export)
game_event :: proc(e: ^sapp.Event) {
  #partial switch e.type {
  case .KEY_DOWN:
    if e.key_code == .R {
      force_reset = true
    }
  }
}
