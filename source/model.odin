package game

import "base:intrinsics"
import "core:fmt"
import "core:strings"
import sg "sokol/gfx"
import "vendor:cgltf"
import stbi "vendor:stb/image"

load_object :: proc(name: string) {
  options: cgltf.options
  path := strings.unsafe_string_to_cstring(name)

  data, result := cgltf.parse_file(options, path)
  if result != .success {
    fmt.println("Failed to parse file", result)
  }
  defer cgltf.free(data)

  result = cgltf.load_buffers(options, data, path)
  if result != .success {
    fmt.println("Failed to load buffers")
    return
  }

  // tm: [16]f32
  // cgltf.node_transform_world(data.animations[0].channels[1].target_node, &tm[0])

  assert(len(data.meshes) == 1)
  assert(len(data.meshes[0].primitives) == 1)

  for mesh in data.meshes {
    for &primitive in mesh.primitives {
      parse_vertices(&primitive)
      parse_indices(&primitive)
      parse_texture(&data.textures[0])
    }
  }

  free_all(context.temp_allocator)
}

parse_vertices :: proc(primitive: ^cgltf.primitive) {
  attribute_arrays: [5]struct {
    data: []f32,
    size: uint,
  }

  for a, i in primitive.attributes {
    floats_count := cgltf.accessor_unpack_floats(a.data, nil, 0)
    size := a.data.stride / (a.type == .joints ? 1 : 4)
    data := make([]f32, floats_count, context.temp_allocator)

    _ = cgltf.accessor_unpack_floats(a.data, &data[0], floats_count)

    attribute_arrays[i] = {data, size}
  }

  vertices_count: uint
  stride: uint
  vertices := make([dynamic]f32, context.temp_allocator)

  for arr in attribute_arrays {
    vertices_count += len(arr.data)
    stride += arr.size
  }

  data_count := vertices_count / stride

  for i in 0 ..< data_count {
    for arr in attribute_arrays {
      append(&vertices, ..arr.data[i * arr.size:(i * arr.size) + arr.size])
    }
  }

  g.mesh.bindings.vertex_buffers[0] = sg.make_buffer(
    {data = {ptr = &vertices[0], size = uint(size_of(f32) * vertices_count)}},
  )
}

parse_indices :: proc(primitve: ^cgltf.primitive) {
  indices_count := cgltf.accessor_unpack_indices(primitve.indices, nil, 0, 0)
  indices := make([]u16, indices_count, context.temp_allocator)
  _ = cgltf.accessor_unpack_indices(primitve.indices, &indices[0], size_of(u16), indices_count)

  g.mesh.bindings.index_buffer = sg.make_buffer(
    {type = .INDEXBUFFER, data = {ptr = &indices[0], size = uint(size_of(u16) * indices_count)}},
  )

  g.mesh.face_count = indices_count
}

parse_texture :: proc(texture: ^cgltf.texture) {
  image_buffer := texture.image_.buffer_view
  texture_bytes := cgltf.buffer_view_data(image_buffer)

  width, height, channels: i32
  pixels := stbi.load_from_memory(
    texture_bytes,
    i32(image_buffer.size),
    &width,
    &height,
    &channels,
    0,
  )
  if pixels == nil {
    fmt.println("Failed to load texture")
    return
  }
  defer stbi.image_free(pixels)

  g.mesh.bindings.images[IMG_uTexture] = sg.make_image(
    {
      width = i32(width),
      height = i32(height),
      pixel_format = .RGBA8,
      data = {subimage = {0 = {0 = {ptr = pixels, size = uint(width * height * 4)}}}},
    },
  )

  g.mesh.bindings.samplers[SMP_uTextureSmp] = sg.make_sampler({})
}
