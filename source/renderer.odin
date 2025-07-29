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

build_grass :: proc(id: BindingID) {
  vertices := []Sb_Vertex {
    // Triangle (top)
    {position = {0.0, 0.1, 0.5}, texcoord = {0.5, 0.0}, normal_pos = {0, 0, 0}}, // top-center
    {position = {0.1, -0.1, 0.5}, texcoord = {1.0, 0.222}, normal_pos = {0, 0, 0}}, // bottom-right
    {position = {-0.1, -0.1, 0.5}, texcoord = {0.0, 0.222}, normal_pos = {0, 0, 0}}, // bottom-left

    // Quad 1 (middle)
    {position = {-0.1, -0.1, 0.5}, texcoord = {0.0, 0.222}, normal_pos = {0, 0, 0}}, // top-left
    {position = {0.1, -0.1, 0.5}, texcoord = {1.0, 0.222}, normal_pos = {0, 0, 0}}, // top-right
    {position = {0.1, -0.4, 0.5}, texcoord = {1.0, 0.555}, normal_pos = {0, 0, 0}}, // bottom-right
    {position = {-0.1, -0.4, 0.5}, texcoord = {0.0, 0.555}, normal_pos = {0, 0, 0}}, // bottom-left

    // Quad 2 (bottom)
    {position = {-0.1, -0.4, 0.5}, texcoord = {0.0, 0.555}, normal_pos = {0, 0, 0}}, // top-left
    {position = {0.1, -0.4, 0.5}, texcoord = {1.0, 0.555}, normal_pos = {0, 0, 0}}, // top-right
    {position = {0.1, -0.8, 0.5}, texcoord = {1.0, 1.0}, normal_pos = {0, 0, 0}}, // bottom-right
    {position = {-0.1, -0.8, 0.5}, texcoord = {0.0, 1.0}, normal_pos = {0, 0, 0}}, // bottom-left
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

build_indices :: proc(num: u16, grid_size: u16) -> []u16 {
  indices := make([dynamic]u16, 0, num)

  for z in 0 ..< grid_size {
    for x in 0 ..< grid_size {
      top_left := z * (grid_size + 1) + x
      top_right := top_left + 1
      bottom_left := (z + 1) * (grid_size + 1) + x
      bottom_right := bottom_left + 1

      append(&indices, top_left, bottom_left, top_right)
      append(&indices, top_right, bottom_left, bottom_right)
    }
  }

  return indices[:]
}
