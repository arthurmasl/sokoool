package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

Game_Memory :: struct {
  camera: Camera,
  pass:   sg.Pass_Action,
  cube:   Entity,
}

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  camera_init()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()
  
  // odinfmt: disable
  vertices := []Sb_Vertex {
    {pos = {-1.0, -1.0, -1.0}, color = {1.0, 0.0, 0.0, 1.0}},
    {pos = {1.0, -1.0, -1.0},  color = {1.0, 0.0, 0.0, 1.0}},
    {pos = {1.0, 1.0, -1.0},   color = {1.0, 0.0, 0.0, 1.0}},
    {pos = {-1.0, 1.0, -1.0},  color = {1.0, 0.0, 0.0, 1.0}},
    {pos = {-1.0, -1.0, 1.0},  color = {0.0, 1.0, 0.0, 1.0}},
    {pos = {1.0, -1.0, 1.0},   color = {0.0, 1.0, 0.0, 1.0}},
    {pos = {1.0, 1.0, 1.0},    color = {0.0, 1.0, 0.0, 1.0}},
    {pos = {-1.0, 1.0, 1.0},   color = {0.0, 1.0, 0.0, 1.0}},
    {pos = {-1.0, -1.0, -1.0}, color = {0.0, 0.0, 1.0, 1.0}},
    {pos = {-1.0, 1.0, -1.0},  color = {0.0, 0.0, 1.0, 1.0}},
    {pos = {-1.0, 1.0, 1.0},   color = {0.0, 0.0, 1.0, 1.0}},
    {pos = {-1.0, -1.0, 1.0},  color = {0.0, 0.0, 1.0, 1.0}},
    {pos = {1.0, -1.0, -1.0},  color = {1.0, 0.5, 0.0, 1.0}},
    {pos = {1.0, 1.0, -1.0},   color = {1.0, 0.5, 0.0, 1.0}},
    {pos = {1.0, 1.0, 1.0},    color = {1.0, 0.5, 0.0, 1.0}},
    {pos = {1.0, -1.0, 1.0},   color = {1.0, 0.5, 0.0, 1.0}},
    {pos = {-1.0, -1.0, -1.0}, color = {0.0, 0.5, 1.0, 1.0}},
    {pos = {-1.0, -1.0, 1.0},  color = {0.0, 0.5, 1.0, 1.0}},
    {pos = {1.0, -1.0, 1.0},   color = {0.0, 0.5, 1.0, 1.0}},
    {pos = {1.0, -1.0, -1.0},  color = {0.0, 0.5, 1.0, 1.0}},
    {pos = {-1.0, 1.0, -1.0},  color = {1.0, 0.0, 0.5, 1.0}},
    {pos = {-1.0, 1.0, 1.0},   color = {1.0, 0.0, 0.5, 1.0}},
    {pos = {1.0, 1.0, 1.0},    color = {1.0, 0.0, 0.5, 1.0}},
    {pos = {1.0, 1.0, -1.0},   color = {1.0, 0.0, 0.5, 1.0}},
  }
  indices:= []u16{
    0, 1, 2,  0, 2, 3,
    6, 5, 4,  7, 6, 4,
    8, 9, 10,  8, 10, 11,
    14, 13, 12,  15, 14, 12,
    16, 17, 18,  16, 18, 19,
    22, 21, 20,  23, 22, 20,
  }
  // odinfmt: enable

  storage_buffer := sg.make_buffer({usage = {storage_buffer = true}, data = sg_range(vertices)})
  index_buffer := sg.make_buffer({usage = {index_buffer = true}, data = sg_range(indices)})
  pipeline := sg.make_pipeline(
    {
      shader = sg.make_shader(base_shader_desc(sg.query_backend())),
      index_type = .UINT16,
      cull_mode = .BACK,
      depth = {write_enabled = true, compare = .LESS_EQUAL},
    },
  )

  g.cube = {
    pip = pipeline,
    bind = {storage_buffers = {SBUF_ssbo = storage_buffer}, index_buffer = index_buffer},
  }

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  model := linalg.matrix4_translate_f32({-1, 1, -1})
  vs_params := Vs_Params {
    mvp = projection * view * model,
  }

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.cube.pip)
  sg.apply_bindings(g.cube.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(0, 36, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
