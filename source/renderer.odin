package game

import sg "sokol/gfx"
import sshape "sokol/shape"

vertices: [64 * 1024]f32
indices: [64 * 1024]u16

shape_buffer := sshape.Buffer {
  vertices = {buffer = {ptr = &vertices, size = size_of(vertices)}},
  indices = {buffer = {ptr = &indices, size = size_of(indices)}},
}

build_shape :: proc(id: BindingID, desc: sshape.Plane) {
  buffer := sshape.build_plane(
    shape_buffer,
    {width = TERRAIN_WIDTH, depth = TERRAIN_HEIGHT, tiles = TERRAIN_TILES},
  )
  g.ranges[id] = sshape.element_range(buffer)
  g.bindings[id].vertex_buffers[0] = sg.make_buffer(sshape.vertex_buffer_desc(buffer))
  g.bindings[id].index_buffer = sg.make_buffer(sshape.index_buffer_desc(buffer))
}
