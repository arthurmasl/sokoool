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
  vertices := []Sb_Vertex {
    {position = {0.0, 0.1, 0.5}, texcoord = {1, 0}, normal_pos = {0, 0, 0}}, // t
    {position = {0.1, -0.1, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // r
    {position = {-0.1, -0.1, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // l
    // quad
    {position = {-0.1, -0.1, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // tl
    {position = {0.1, -0.1, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // tr
    {position = {0.1, -0.4, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // br
    {position = {-0.1, -0.4, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // bl
    // quad 2
    {position = {-0.1, -0.4, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // tl
    {position = {0.1, -0.4, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // tr
    {position = {0.1, -0.8, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // br
    {position = {-0.1, -0.8, 0.5}, texcoord = {0, 1}, normal_pos = {0, 0, 0}}, // bl
  }
  
  // odinfmt: disable
  indices := []u16{
    0, 1, 2,
    3, 4, 5, 3, 5, 6,
    7, 8, 9, 7, 9, 10,
  }
  // odinfmt: enable

  g.bindings[id].storage_buffers = {
    SBUF_vertices  = sg.make_buffer(
      {usage = {storage_buffer = true}, data = sg_range(vertices)},
    ),
    SBUF_instances = sg.make_buffer(
      {
        usage = {storage_buffer = true, stream_update = true},
        size = GRASS_COUNT * size_of(Sb_Instance),
      },
    ),
  }
  g.bindings[id].index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(indices)},
  )
  g.ranges[id] = sshape.Element_Range {
    base_element = 0,
    num_elements = 15,
  }
}
