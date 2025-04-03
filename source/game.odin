package game

import "core:math/linalg"

import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()

  // vertex buffer
  vertices := []Vertex {
    {pos = {-0.5, -0.5, -0.5}, uvs = {0.0, 0.0}},
    {pos = {0.5, -0.5, -0.5}, uvs = {1.0, 0.0}},
    {pos = {0.5, 0.5, -0.5}, uvs = {1.0, 1.0}},
    {pos = {0.5, 0.5, -0.5}, uvs = {1.0, 1.0}},
    {pos = {-0.5, 0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {-0.5, -0.5, -0.5}, uvs = {0.0, 0.0}},
    {pos = {-0.5, -0.5, 0.5}, uvs = {0.0, 0.0}},
    {pos = {0.5, -0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {0.5, 0.5, 0.5}, uvs = {1.0, 1.0}},
    {pos = {0.5, 0.5, 0.5}, uvs = {1.0, 1.0}},
    {pos = {-0.5, 0.5, 0.5}, uvs = {0.0, 1.0}},
    {pos = {-0.5, -0.5, 0.5}, uvs = {0.0, 0.0}},
    {pos = {-0.5, 0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {-0.5, 0.5, -0.5}, uvs = {1.0, 1.0}},
    {pos = {-0.5, -0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {-0.5, -0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {-0.5, -0.5, 0.5}, uvs = {0.0, 0.0}},
    {pos = {-0.5, 0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {0.5, 0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {0.5, 0.5, -0.5}, uvs = {1.0, 1.0}},
    {pos = {0.5, -0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {0.5, -0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {0.5, -0.5, 0.5}, uvs = {0.0, 0.0}},
    {pos = {0.5, 0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {-0.5, -0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {0.5, -0.5, -0.5}, uvs = {1.0, 1.0}},
    {pos = {0.5, -0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {0.5, -0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {-0.5, -0.5, 0.5}, uvs = {0.0, 0.0}},
    {pos = {-0.5, -0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {-0.5, 0.5, -0.5}, uvs = {0.0, 1.0}},
    {pos = {0.5, 0.5, -0.5}, uvs = {1.0, 1.0}},
    {pos = {0.5, 0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {0.5, 0.5, 0.5}, uvs = {1.0, 0.0}},
    {pos = {-0.5, 0.5, 0.5}, uvs = {0.0, 0.0}},
    {pos = {-0.5, 0.5, -0.5}, uvs = {0.0, 1.0}},
  }
  g.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})

  img := load_image("assets/round_cat.png")

  // texture
  g.bind.images[IMG_tex] = sg.make_image(
    {width = i32(img.width), height = i32(img.height), data = {subimage = {0 = {0 = sg_range(img)}}}},
  )

  // sampler
  g.bind.samplers[SMP_smp] = sg.make_sampler({})

  // pipeline
  g.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(simple_shader_desc(sg.query_backend())),
      layout = {attrs = {ATTR_simple_pos = {format = .FLOAT3}, ATTR_simple_uvs0 = {format = .FLOAT2}}},
      depth = {compare = .LESS_EQUAL, write_enabled = true},
      // primitive_type = .LINES,
    },
  )

  // clear
  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
  }
}

@(export)
game_frame :: proc() {
  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.pip)
  sg.apply_bindings(g.bind)

  now := f32(stm.sec(stm.now()))
  rxm := linalg.matrix4_rotate_f32(linalg.RAD_PER_DEG * -65 * now, {0, 1, 0})
  rym := linalg.matrix4_rotate_f32(linalg.RAD_PER_DEG * -120, {0, 0, 1})
  model := rxm * rym

  view := linalg.matrix4_translate_f32({0, 0, -3})
  projection := linalg.matrix4_perspective(45, sapp.widthf() / sapp.heightf(), 0.1, 100.0)

  vs_params := Vs_Params {
    model      = model,
    view       = view,
    projection = projection,
  }
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))

  sg.draw(0, 36, 1)
  sg.end_pass()
  sg.commit()
}
