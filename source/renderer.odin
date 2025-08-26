package game

import sg "sokol/gfx"
import sshape "sokol/shape"

ShapeType :: union {
  sshape.Plane,
  sshape.Box,
  sshape.Sphere,
  sshape.Cylinder,
  sshape.Torus,
}

vertices: [64 * 1024]f32
indices: [64 * 1024]u16

shape_buffer := sshape.Buffer {
  vertices = {buffer = {ptr = &vertices, size = size_of(vertices)}},
  indices = {buffer = {ptr = &indices, size = size_of(indices)}},
}

build_shape :: proc(id: BindingID, desc: ShapeType) {
  buffer: sshape.Buffer

  switch d in desc {
  case sshape.Plane:
    buffer = sshape.build_plane(shape_buffer, d)
  case sshape.Box:
    buffer = sshape.build_box(shape_buffer, d)
  case sshape.Sphere:
    buffer = sshape.build_sphere(shape_buffer, d)
  case sshape.Cylinder:
    buffer = sshape.build_cylinder(shape_buffer, d)
  case sshape.Torus:
    buffer = sshape.build_torus(shape_buffer, d)
  }

  g.bindings[id].vertex_buffers[0] = sg.make_buffer(sshape.vertex_buffer_desc(buffer))
  g.bindings[id].index_buffer = sg.make_buffer(sshape.index_buffer_desc(buffer))
  g.ranges[id] = sshape.element_range(buffer)
}
