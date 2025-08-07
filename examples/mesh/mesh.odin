package mesh

import sg "../sokol/gfx"
import "../types"
import "base:intrinsics"
import "core:fmt"
import "core:strings"
import "vendor:cgltf"
import stbi "vendor:stb/image"

Mesh :: struct #packed {
  pipeline:         sg.Pipeline,
  bindings:         sg.Bindings,
  indices_count:    uint,
  //
  joints:           [50]types.Mat4,
  inverse_matrices: []types.Mat4,
  animations:       []Animation,
}

Animation :: struct #packed {
  channels:   []Channel,
  start_time: f32,
}

Channel :: struct #packed {
  time_indices:     []f32,
  transform_values: []f32,
  //
  target_node:      ^cgltf.node,
  target_path:      cgltf.animation_path_type,
  values_count:     uint,
}

mesh_data: ^cgltf.data

@(export)
load :: proc(file_name: string) -> Mesh {
  options: cgltf.options
  path := strings.unsafe_string_to_cstring(file_name)

  data, result := cgltf.parse_file(options, path)
  mesh_data = data
  if result != .success {
    fmt.println("Failed to parse file", result)
  }

  result = cgltf.load_buffers(options, data, path)
  if result != .success {
    fmt.println("Failed to load buffers")
    return {}
  }

  assert(len(data.meshes) == 1)
  assert(len(data.meshes[0].primitives) == 1)

  mesh: Mesh

  parse_vertices(&data.meshes[0].primitives[0], &mesh)
  parse_indices(&data.meshes[0].primitives[0], &mesh)
  parse_texture(&data.textures[0], &mesh)

  init_skin(&data.skins[0], &mesh)
  init_animations(data.animations[:], &data.skins[0], &mesh)

  return mesh
}

parse_vertices :: proc(primitive: ^cgltf.primitive, mesh: ^Mesh) {
  attribute_packs: [5]struct {
    data: []f32,
    size: uint,
  }

  for attribute, i in primitive.attributes {
    attribute_packs[i] = {
      data = get_unpacked_data(attribute.data),
      size = get_component_size(attribute.data),
    }
  }
  defer for attribute in attribute_packs do delete(attribute.data)

  vertices_count: uint
  stride: uint
  for pack in attribute_packs {
    vertices_count += len(pack.data)
    stride += pack.size
  }

  vertices := make([dynamic]f32, context.temp_allocator)
  blocks_count := vertices_count / stride

  for i in 0 ..< blocks_count {
    for pack in attribute_packs {
      append(&vertices, ..pack.data[i * pack.size:(i * pack.size) + pack.size])
    }
  }

  mesh.bindings.vertex_buffers[0] = sg.make_buffer(
    {data = {ptr = &vertices[0], size = uint(size_of(f32) * vertices_count)}},
  )
}

parse_indices :: proc(primitve: ^cgltf.primitive, mesh: ^Mesh) {
  indices, indices_count := get_unpacked_indices(primitve.indices)

  mesh.bindings.index_buffer = sg.make_buffer(
    {type = .INDEXBUFFER, data = {ptr = &indices[0], size = uint(size_of(u16) * indices_count)}},
  )

  mesh.indices_count = indices_count
}

parse_texture :: proc(texture: ^cgltf.texture, mesh: ^Mesh) {
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

  mesh.bindings.images[0] = sg.make_image(
    {
      width = i32(width),
      height = i32(height),
      pixel_format = .RGBA8,
      data = {subimage = {0 = {0 = {ptr = pixels, size = uint(width * height * 4)}}}},
    },
  )

  mesh.bindings.samplers[0] = sg.make_sampler({})
}

@(export)
free_memory :: proc(mesh: ^Mesh) {
  for animation in mesh.animations {
    for channel in animation.channels {
      delete(channel.time_indices)
      delete(channel.transform_values)
    }
    delete(animation.channels)
  }
  delete(mesh.animations)
  delete(mesh.inverse_matrices)

  cgltf.free(mesh_data)
}
