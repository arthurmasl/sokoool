package game

import "core:image/png"
import "core:log"
import "core:slice"

import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"

@(export)
game_init :: proc() {
  g = new(Game_Memory)

  game_hot_reloaded(g)

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

  // The remainder of this proc just sets up a sample cube and loads the
  // texture to put on the cube's sides.
  //
  // The cube is from https://github.com/floooh/sokol-odin/blob/main/examples/cube/main.odin

  /*
		Cube vertex buffer with packed vertex formats for color and texture coords.
		Note that a vertex format which must be portable across all
		backends must only use the normalized integer formats
		(BYTE4N, UBYTE4N, SHORT2N, SHORT4N), which can be converted
		to floating point formats in the vertex shader inputs.
	*/

  vertices := [?]Vertex {
    // pos               color       uvs
    {-1.0, -1.0, -1.0, 0xFF0000FF, 0, 0},
    {1.0, -1.0, -1.0, 0xFF0000FF, 32767, 0},
    {1.0, 1.0, -1.0, 0xFF0000FF, 32767, 32767},
    {-1.0, 1.0, -1.0, 0xFF0000FF, 0, 32767},
    {-1.0, -1.0, 1.0, 0xFF00FF00, 0, 0},
    {1.0, -1.0, 1.0, 0xFF00FF00, 32767, 0},
    {1.0, 1.0, 1.0, 0xFF00FF00, 32767, 32767},
    {-1.0, 1.0, 1.0, 0xFF00FF00, 0, 32767},
    {-1.0, -1.0, -1.0, 0xFFFF0000, 0, 0},
    {-1.0, 1.0, -1.0, 0xFFFF0000, 32767, 0},
    {-1.0, 1.0, 1.0, 0xFFFF0000, 32767, 32767},
    {-1.0, -1.0, 1.0, 0xFFFF0000, 0, 32767},
    {1.0, -1.0, -1.0, 0xFFFF007F, 0, 0},
    {1.0, 1.0, -1.0, 0xFFFF007F, 32767, 0},
    {1.0, 1.0, 1.0, 0xFFFF007F, 32767, 32767},
    {1.0, -1.0, 1.0, 0xFFFF007F, 0, 32767},
    {-1.0, -1.0, -1.0, 0xFFFF7F00, 0, 0},
    {-1.0, -1.0, 1.0, 0xFFFF7F00, 32767, 0},
    {1.0, -1.0, 1.0, 0xFFFF7F00, 32767, 32767},
    {1.0, -1.0, -1.0, 0xFFFF7F00, 0, 32767},
    {-1.0, 1.0, -1.0, 0xFF007FFF, 0, 0},
    {-1.0, 1.0, 1.0, 0xFF007FFF, 32767, 0},
    {1.0, 1.0, 1.0, 0xFF007FFF, 32767, 32767},
    {1.0, 1.0, -1.0, 0xFF007FFF, 0, 32767},
  }
  g.bind.vertex_buffers[0] = sg.make_buffer({data = {ptr = &vertices, size = size_of(vertices)}})

  // create an index buffer for the cube
  indices := [?]u16 {
    0,
    1,
    2,
    0,
    2,
    3,
    6,
    5,
    4,
    7,
    6,
    4,
    8,
    9,
    10,
    8,
    10,
    11,
    14,
    13,
    12,
    15,
    14,
    12,
    16,
    17,
    18,
    16,
    18,
    19,
    22,
    21,
    20,
    23,
    22,
    20,
  }
  g.bind.index_buffer = sg.make_buffer({type = .INDEXBUFFER, data = {ptr = &indices, size = size_of(indices)}})

  if img_data, img_data_ok := read_entire_file("assets/round_cat.png", context.temp_allocator); img_data_ok {
    if img, img_err := png.load_from_bytes(img_data, allocator = context.temp_allocator); img_err == nil {
      g.bind.images[IMG_tex] = sg.make_image(
        {
          width = i32(img.width),
          height = i32(img.height),
          data = {subimage = {0 = {0 = {ptr = raw_data(img.pixels.buf), size = uint(slice.size(img.pixels.buf[:]))}}}},
        },
      )
    } else {
      log.error(img_err)
    }
  } else {
    log.error("Failed loading texture")
  }

  // a sampler with default options to sample the above image as texture
  g.bind.samplers[SMP_smp] = sg.make_sampler({})

  // shader and pipeline object
  g.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(texcube_shader_desc(sg.query_backend())),
      layout = {
        attrs = {
          ATTR_texcube_pos = {format = .FLOAT3},
          ATTR_texcube_color0 = {format = .UBYTE4N},
          ATTR_texcube_texcoord0 = {format = .SHORT2N},
        },
      },
      index_type = .UINT16,
      cull_mode = .BACK,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
    },
  )
}
