package game

import "base:intrinsics"
import "core:fmt"
import "core:image/png"
import "core:log"
import "core:os"
import "core:strings"
import "vendor:cgltf"

import "web"

import sg "sokol/gfx"

_ :: os
_ :: web

IS_WEB :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

// Wraps os.read_entire_file and os.write_entire_file, but they also work with emscripten.
@(require_results)
read_entire_file :: proc(
  name: string,
  allocator := context.allocator,
  loc := #caller_location,
) -> (
  data: []byte,
  success: bool,
) {
  when IS_WEB {
    return web.read_entire_file(name, allocator, loc)
  } else {
    return os.read_entire_file(name, allocator, loc)
  }
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
  when IS_WEB {
    return web.write_entire_file(name, data, truncate)
  } else {
    return os.write_entire_file(name, data, truncate)
  }
}

load_image :: proc(name: string) -> ^png.Image {
  img_data, img_data_ok := read_entire_file(name, context.temp_allocator)
  if !img_data_ok {
    log.error("Failed loading texture")
  }

  img, img_err := png.load_from_bytes(img_data, nil, context.temp_allocator)
  if img_err != nil {
    log.error(img_err)
  }

  return img
}

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

  for mesh in data.meshes {
    for p in mesh.primitives {
      position_arr: []f32
      normal_arr: []f32
      texcoord_arr: []f32

      for a in p.attributes {
        num_floats := cgltf.accessor_unpack_floats(a.data, nil, 0)
        if a.type == .position {
          position_arr = make([]f32, num_floats, context.temp_allocator)
          _ = cgltf.accessor_unpack_floats(a.data, &position_arr[0], num_floats)
        }
        if a.type == .normal {
          normal_arr = make([]f32, num_floats, context.temp_allocator)
          _ = cgltf.accessor_unpack_floats(a.data, &normal_arr[0], num_floats)
        }
        if a.type == .texcoord {
          texcoord_arr = make([]f32, num_floats, context.temp_allocator)
          _ = cgltf.accessor_unpack_floats(a.data, &texcoord_arr[0], num_floats)
        }
      }

      vertices := make([dynamic]f32, context.temp_allocator)
      vertices_count := (len(position_arr) + len(normal_arr) + len(texcoord_arr)) / 8

      for i in 0 ..< vertices_count {
        append(&vertices, ..position_arr[i * 3:(i * 3) + 3])
        append(&vertices, ..normal_arr[i * 3:(i * 3) + 3])
        append(&vertices, ..texcoord_arr[i * 2:(i * 2) + 2])
      }

      indices_count := cgltf.accessor_unpack_indices(p.indices, nil, 0, 0)
      indices := make([]u16, indices_count, context.temp_allocator)
      _ = cgltf.accessor_unpack_indices(p.indices, &indices[0], size_of(u16), indices_count)

      g.mesh.bindings.vertex_buffers[0] = sg.make_buffer(
        {data = {ptr = &vertices[0], size = uint(size_of(f32) * 8 * vertices_count)}},
      )
      g.mesh.bindings.index_buffer = sg.make_buffer(
        {
          type = .INDEXBUFFER,
          data = {ptr = &indices[0], size = uint(size_of(u16) * indices_count)},
        },
      )

      g.mesh.face_count = len(indices)
    }
  }

  free_all(context.temp_allocator)
}

sg_range :: proc {
  sg_range_from_slice,
  sg_range_from_struct,
}

sg_range_from_slice :: proc(sl: []$T) -> sg.Range {
  return {ptr = raw_data(sl), size = uint(slice.size(sl))}
}

sg_range_from_struct :: proc(st: ^$T) -> sg.Range where intrinsics.type_is_struct(T) {
  when T == png.Image {
    return {ptr = raw_data(st.pixels.buf), size = uint(slice.size(st.pixels.buf[:]))}
  }

  return {ptr = st, size = size_of(T)}
}
