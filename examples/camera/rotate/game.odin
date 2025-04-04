package game

import "core:math"
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

  vertices := []Vertex {
    {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
    {pos = {1.0, -1.0, -1.0}, uvs = {1, 0}},
    {pos = {1.0, 1.0, -1.0}, uvs = {1, 1}},
    {pos = {-1.0, 1.0, -1.0}, uvs = {0, 1}},
    {pos = {-1.0, -1.0, 1.0}, uvs = {0, 0}},
    {pos = {1.0, -1.0, 1.0}, uvs = {1, 0}},
    {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
    {pos = {-1.0, 1.0, 1.0}, uvs = {0, 1}},
    {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
    {pos = {-1.0, 1.0, -1.0}, uvs = {1, 0}},
    {pos = {-1.0, 1.0, 1.0}, uvs = {1, 1}},
    {pos = {-1.0, -1.0, 1.0}, uvs = {0, 1}},
    {pos = {1.0, -1.0, -1.0}, uvs = {0, 0}},
    {pos = {1.0, 1.0, -1.0}, uvs = {1, 0}},
    {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
    {pos = {1.0, -1.0, 1.0}, uvs = {0, 1}},
    {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
    {pos = {-1.0, -1.0, 1.0}, uvs = {1, 0}},
    {pos = {1.0, -1.0, 1.0}, uvs = {1, 1}},
    {pos = {1.0, -1.0, -1.0}, uvs = {0, 1}},
    {pos = {-1.0, 1.0, -1.0}, uvs = {0, 0}},
    {pos = {-1.0, 1.0, 1.0}, uvs = {1, 0}},
    {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
    {pos = {1.0, 1.0, -1.0}, uvs = {0, 1}},
  }
  
  // odinfmt: disable
  indices := [?]u16 {
		0, 1, 2,  0, 2, 3,
		6, 5, 4,  7, 6, 4,
		8, 9, 10,  8, 10, 11,
		14, 13, 12,  15, 14, 12,
		16, 17, 18,  16, 18, 19,
		22, 21, 20,  23, 22, 20,
	}
  // odinfmt: enable

  g.bind.index_buffer = sg.make_buffer(
    {type = .INDEXBUFFER, data = {ptr = &indices, size = size_of(indices)}},
  )

  g.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})

  img := load_image("assets/round_cat.png")
  g.bind.samplers[SMP_smp] = sg.make_sampler({})
  g.bind.images[IMG_tex] = sg.make_image(
    {
      width = i32(img.width),
      height = i32(img.height),
      data = {subimage = {0 = {0 = sg_range(img)}}},
    },
  )

  g.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(simple_shader_desc(sg.query_backend())),
      layout = {
        attrs = {ATTR_simple_pos = {format = .FLOAT3}, ATTR_simple_uvs0 = {format = .FLOAT2}},
      },
      index_type = .UINT16,
      cull_mode = .BACK,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
      // primitive_type = .LINES,
    },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
  }
}

cubes_pos :: [?]Vec3 {
  {1, 0, 0},
  {5, 0, 2},
  {0, 5, 2},
  {1, -3, 8},
  {0, 9, 3},
  {5, 2, 8},
  {-5, 0, 5},
  {-5, 2, -3},
  {4, 1, -7},
}

RADIUS :: 30.0

@(export)
game_frame :: proc() {
  now := f32(stm.sec(stm.now()))

  camX := math.sin_f32(now) * RADIUS
  camZ := math.cos_f32(now) * RADIUS

  view := linalg.matrix4_look_at_f32(Vec3{camX, 0, camZ}, Vec3{}, Vec3{0, 1, 0})
  projection := linalg.matrix4_perspective_f32(45, sapp.widthf() / sapp.heightf(), 0.1, 100.0)

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.pip)
  sg.apply_bindings(g.bind)

  vs_params := Vs_Params{{view = view, projection = projection}}

  for pos in cubes_pos {
    vs_params.model =
      linalg.matrix4_translate_f32(pos) *
      linalg.matrix4_rotate_f32(linalg.RAD_PER_DEG * -65 * f32(now), pos)

    sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))

    sg.draw(0, 36, 1)
  }

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
