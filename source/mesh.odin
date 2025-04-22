package game

import "base:intrinsics"
import "core:fmt"
import "core:math/linalg"
import "core:strings"
import sg "sokol/gfx"
import "vendor:cgltf"
import stbi "vendor:stb/image"

load_mesh :: proc(file_name: string) {
  options: cgltf.options
  path := strings.unsafe_string_to_cstring(file_name)

  data, result := cgltf.parse_file(options, path)
  if result != .success {
    fmt.println("Failed to parse file", result)
  }
  // defer cgltf.free(data)

  result = cgltf.load_buffers(options, data, path)
  if result != .success {
    fmt.println("Failed to load buffers")
    return
  }

  assert(len(data.meshes) == 1)
  assert(len(data.meshes[0].primitives) == 1)

  parse_vertices(&data.meshes[0].primitives[0])
  parse_indices(&data.meshes[0].primitives[0])
  parse_texture(&data.textures[0])
  // parse_animation(&data.animations[0], &data.skins[0])

  g.mesh.animation = &data.animations[0]
  g.mesh.skin = &data.skins[0]
}

parse_vertices :: proc(primitive: ^cgltf.primitive) {
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

  g.mesh.bindings.vertex_buffers[0] = sg.make_buffer(
    {data = {ptr = &vertices[0], size = uint(size_of(f32) * vertices_count)}},
  )
}

parse_indices :: proc(primitve: ^cgltf.primitive) {
  indices, indices_count := get_unpacked_indices(primitve.indices)

  g.mesh.bindings.index_buffer = sg.make_buffer(
    {type = .INDEXBUFFER, data = {ptr = &indices[0], size = uint(size_of(u16) * indices_count)}},
  )

  g.mesh.indices_count = indices_count
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

parse_animation :: proc(time: f32, animation: ^cgltf.animation, skin: ^cgltf.skin) {
  if time >= 1.1 do return

  // apply transforms
  for channel in animation.channels {
    sampler := channel.sampler
    input_data := get_unpacked_data(sampler.input)
    output_data := get_unpacked_data(sampler.output)

    values_count := sampler.output.stride / cgltf.component_size(sampler.output.component_type)
    raw_from := output_data[:int(values_count)]
    raw_to := output_data[len(output_data) - int(values_count):]

    // if sampler.interpolation != .linear do continue
    fmt.println(
      "vec",
      values_count,
      channel.target_path,
      sampler.interpolation,
      channel.target_node.name,
    )
    // fmt.println(len(input_data))
    fmt.println(len(input_data), input_data)
    fmt.println(len(output_data), output_data)
    fmt.println()

    #partial switch channel.target_path {
    case .scale, .translation:
      from := Vec3{raw_from[0], raw_from[1], raw_from[2]}
      to := Vec3{raw_to[0], raw_to[1], raw_to[2]}

      interpolated := linalg.lerp(from, to, time)

      #partial switch channel.target_path {
      case .translation:
        channel.target_node.translation = interpolated
      case .scale:
        channel.target_node.scale = interpolated
      }

    case .rotation:
      from := quaternion(x = raw_from[0], y = raw_from[1], z = raw_from[2], w = raw_from[3])
      to := quaternion(x = raw_to[0], y = raw_to[1], z = raw_to[2], w = raw_to[3])

      quat := linalg.quaternion_slerp(from, to, time)
      interpolated := Vec4{quat.x, quat.y, quat.z, quat.w}

      channel.target_node.rotation = interpolated
    }
  }

  fmt.println(len(animation.channels))

  // apply matrices
  joint_matrices: [50]Mat4
  inverse_matrices := get_inverse_matrices(skin)

  for joint, i in skin.joints {
    flat_matrix: [4 * 4]f32
    cgltf.node_transform_world(joint, &flat_matrix[0])

    transform := transmute(Mat4)(flat_matrix)
    joint_matrices[i] = transform * inverse_matrices[i]
  }

  g.mesh.bones = joint_matrices
}

get_unpacked_data :: proc(accessor: ^cgltf.accessor) -> []f32 {
  data_count := cgltf.accessor_unpack_floats(accessor, nil, 0)
  data := make([]f32, data_count, context.temp_allocator)
  _ = cgltf.accessor_unpack_floats(accessor, &data[0], data_count)

  return data
}

get_unpacked_indices :: proc(accessor: ^cgltf.accessor) -> ([]u16, uint) {
  indices_count := cgltf.accessor_unpack_indices(accessor, nil, 0, 0)
  indices := make([]u16, indices_count, context.temp_allocator)
  _ = cgltf.accessor_unpack_indices(accessor, &indices[0], size_of(u16), indices_count)

  return indices, indices_count
}

get_inverse_matrices :: proc(skin: ^cgltf.skin) -> []Mat4 {
  flat_inverse_matrices := get_unpacked_data(skin.inverse_bind_matrices)
  matrices_count := len(flat_inverse_matrices) / 16
  inverse_matrices := make([]Mat4, matrices_count, context.temp_allocator)

  for m in 0 ..< matrices_count {
    for i in 0 ..< 4 {
      for j in 0 ..< 4 {
        inverse_matrices[m][i][j] = flat_inverse_matrices[m * 16 + i * 4 + j]
      }
    }
  }

  return inverse_matrices
}

get_component_size :: proc(accessor: ^cgltf.accessor) -> uint {
  return accessor.stride / cgltf.component_size(accessor.component_type)
}
