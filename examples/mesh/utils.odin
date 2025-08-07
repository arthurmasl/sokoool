package mesh

import "../types"
import "vendor:cgltf"

get_unpacked_data :: proc(accessor: ^cgltf.accessor) -> []f32 {
  data_count := cgltf.accessor_unpack_floats(accessor, nil, 0)
  data := make([]f32, data_count, context.allocator)
  _ = cgltf.accessor_unpack_floats(accessor, &data[0], data_count)

  return data
}

get_unpacked_indices :: proc(accessor: ^cgltf.accessor) -> ([]u16, uint) {
  indices_count := cgltf.accessor_unpack_indices(accessor, nil, 0, 0)
  indices := make([]u16, indices_count, context.temp_allocator)
  _ = cgltf.accessor_unpack_indices(accessor, &indices[0], size_of(u16), indices_count)

  return indices, indices_count
}

get_inverse_matrices :: proc(skin: ^cgltf.skin) -> []types.Mat4 {
  flat_inverse_matrices := get_unpacked_data(skin.inverse_bind_matrices)
  defer delete(flat_inverse_matrices)
  matrices_count := len(flat_inverse_matrices) / 16
  inverse_matrices := make([]types.Mat4, matrices_count, context.allocator)

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

get_interplation_values :: proc(times: []f32, time: f32) -> (int, int, f32) {
  for i in 0 ..< len(times) - 1 {
    next_time := times[i + 1]
    if time < next_time {
      prev_time := times[i]
      t := (time - prev_time) / (next_time - prev_time)
      return i, i + 1, t
    }
  }

  return len(times) - 2, len(times) - 1, 1.0
}

get_raw_vector :: proc(raw_arr: []f32, from_index: int, values_count: int) -> []f32 {
  return raw_arr[from_index * values_count:from_index * values_count + values_count]
}
