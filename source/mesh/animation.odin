package mesh

import "../types"
import "core:math/linalg"
import "vendor:cgltf"

init_skin :: proc(skin: ^cgltf.skin, mesh: ^Mesh) {
  inverse_matrices := get_inverse_matrices(skin)

  for joint, i in skin.joints {
    flat_matrix: [4 * 4]f32
    cgltf.node_transform_world(joint, &flat_matrix[0])

    transform := transmute(types.Mat4)(flat_matrix)
    mesh.joints[i] = transform * inverse_matrices[i]
  }

  mesh.inverse_matrices = inverse_matrices
}

init_animations :: proc(animations: []cgltf.animation, skin: ^cgltf.skin, mesh: ^Mesh) {
  mesh.animations = make([]Animation, len(animations), context.allocator)

  for animation, animation_index in animations {
    current_animation := &mesh.animations[animation_index]
    current_animation.channels = make([]Channel, len(skin.joints), context.allocator)

    for joint, joint_index in skin.joints {
      for channel in animation.channels {
        if joint != channel.target_node do continue

        current_channel := &current_animation.channels[joint_index]

        sampler := channel.sampler
        values_count := sampler.output.stride / cgltf.component_size(sampler.output.component_type)

        current_channel.time_indices = get_unpacked_data(channel.sampler.input)
        current_channel.transform_values = get_unpacked_data(channel.sampler.output)

        current_channel.target_node = channel.target_node
        current_channel.target_path = channel.target_path
        current_channel.values_count = values_count
      }
    }
  }
}

@(export)
parse_animation :: proc(current_time: f32, animation_index: uint, mesh: ^Mesh) {
  animation := &mesh.animations[animation_index]

  animation_time := current_time - animation.start_time
  if animation_time > 2.1 do animation.start_time = current_time // TODO: temp loop

  // apply transforms
  for channel, i in animation.channels {
    if channel.target_node == nil do continue

    frame_from, frame_to, interpolation_time := get_interplation_values(
      channel.time_indices[:],
      animation_time,
    )

    raw_from := get_raw_vector(channel.transform_values[:], frame_from, int(channel.values_count))
    raw_to := get_raw_vector(channel.transform_values[:], frame_to, int(channel.values_count))

    #partial switch channel.target_path {
    case .scale, .translation:
      from := types.Vec3{raw_from[0], raw_from[1], raw_from[2]}
      to := types.Vec3{raw_to[0], raw_to[1], raw_to[2]}

      interpolated := linalg.lerp(from, to, interpolation_time)

      #partial switch channel.target_path {
      case .translation:
        channel.target_node.translation = interpolated
      case .scale:
        channel.target_node.scale = interpolated
      }

    case .rotation:
      from := quaternion(x = raw_from[0], y = raw_from[1], z = raw_from[2], w = raw_from[3])
      to := quaternion(x = raw_to[0], y = raw_to[1], z = raw_to[2], w = raw_to[3])

      quat := linalg.quaternion_slerp(from, to, interpolation_time)
      interpolated := types.Vec4{quat.x, quat.y, quat.z, quat.w}

      channel.target_node.rotation = interpolated
    }

    flat_matrix: [4 * 4]f32
    cgltf.node_transform_world(channel.target_node, &flat_matrix[0])
    transform := transmute(types.Mat4)(flat_matrix)
    mesh.joints[i] = transform * mesh.inverse_matrices[i]
  }
}
