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

  g.ranges[id] = sshape.element_range(buffer)
  g.bindings[id].vertex_buffers[0] = sg.make_buffer(sshape.vertex_buffer_desc(buffer))
  g.bindings[id].index_buffer = sg.make_buffer(sshape.index_buffer_desc(buffer))
}

build_grass :: proc(id: BindingID) {
  vertices := []struct {
    pos:      Vec3,
    normal:   Vec3,
    texcoord: Vec2,
  } {
    {pos = {0.0, 0.1, 0.5}, texcoord = {1, 0}}, // top
    {pos = {0.1, -0.1, 0.5}, texcoord = {0, 1}}, // right
    {pos = {-0.1, -0.1, 0.5}, texcoord = {0, 1}}, // left
    // quad
    {pos = {-0.1, -0.1, 0.5}, texcoord = {0, 1}}, // tl
    {pos = {0.1, -0.1, 0.5}, texcoord = {0, 1}}, // tr
    {pos = {0.1, -0.4, 0.5}, texcoord = {0, 1}}, // br
    {pos = {-0.1, -0.4, 0.5}, texcoord = {0, 1}}, // bl
    // quad 2
    {pos = {-0.1, -0.4, 0.5}, texcoord = {0, 1}}, // tl
    {pos = {0.1, -0.4, 0.5}, texcoord = {0, 1}}, // tr
    {pos = {0.1, -0.8, 0.5}, texcoord = {0, 1}}, // br
    {pos = {-0.1, -0.8, 0.5}, texcoord = {0, 1}}, // bl
  }
  
  // odinfmt: disable
  indices := []u16{
    0, 1, 2,
    3, 4, 5, 3, 5, 6,
    7, 8, 9, 7, 9, 10,
  }
  // odinfmt: enable

  g.bindings[id].vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})
  g.bindings[id].index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(indices)},
  )
  g.ranges[id] = sshape.Element_Range {
    base_element = 0,
    num_elements = 15,
  }
}
