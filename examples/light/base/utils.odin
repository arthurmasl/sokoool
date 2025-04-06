package game

import "base:intrinsics"
import "core:image/png"
import "core:log"
import "core:os"
import "core:slice"

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

sg_range :: proc {
  sg_range_from_image,
  sg_range_from_slice,
  sg_range_from_struct,
}

sg_range_from_image :: proc(img: ^png.Image) -> sg.Range {
  return {ptr = raw_data(img.pixels.buf), size = uint(slice.size(img.pixels.buf[:]))}
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

CUBE_UVS_VERTICES :: []TexturedVertex {
  {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {1.0, -1.0, -1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, -1.0}, uvs = {1, 1}},
  {pos = {-1.0, 1.0, -1.0}, uvs = {0, 1}},
  {pos = {-1.0, -1.0, 1.0}, uvs = {0, 0}},
  {pos = {1.0, -1.0, 1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {-1.0, 1.0, 1.0}, uvs = {0, 1}},
  {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {-1.0, 1.0, -1.0}, uvs = {1, 0}},
  {pos = {-1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {-1.0, -1.0, 1.0}, uvs = {0, 1}},
  {pos = {1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {1.0, 1.0, -1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {1.0, -1.0, 1.0}, uvs = {0, 1}},
  {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {-1.0, -1.0, 1.0}, uvs = {1, 0}},
  {pos = {1.0, -1.0, 1.0}, uvs = {1, 1}},
  {pos = {1.0, -1.0, -1.0}, uvs = {0, 1}},
  {pos = {-1.0, 1.0, -1.0}, uvs = {0, 0}},
  {pos = {-1.0, 1.0, 1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {1.0, 1.0, -1.0}, uvs = {0, 1}},
}

CUBE_VERTICES :: []Vertex {
  {pos = {-1.0, -1.0, -1.0}},
  {pos = {1.0, -1.0, -1.0}},
  {pos = {1.0, 1.0, -1.0}},
  {pos = {-1.0, 1.0, -1.0}},
  {pos = {-1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, 1.0}},
  {pos = {1.0, 1.0, 1.0}},
  {pos = {-1.0, 1.0, 1.0}},
  {pos = {-1.0, -1.0, -1.0}},
  {pos = {-1.0, 1.0, -1.0}},
  {pos = {-1.0, 1.0, 1.0}},
  {pos = {-1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, -1.0}},
  {pos = {1.0, 1.0, -1.0}},
  {pos = {1.0, 1.0, 1.0}},
  {pos = {1.0, -1.0, 1.0}},
  {pos = {-1.0, -1.0, -1.0}},
  {pos = {-1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, -1.0}},
  {pos = {-1.0, 1.0, -1.0}},
  {pos = {-1.0, 1.0, 1.0}},
  {pos = {1.0, 1.0, 1.0}},
  {pos = {1.0, 1.0, -1.0}},
}


// odinfmt: disable
CUBE_INDICES := []u16 {
  0, 1, 2,  0, 2, 3,
  6, 5, 4,  7, 6, 4,
  8, 9, 10,  8, 10, 11,
  14, 13, 12,  15, 14, 12,
  16, 17, 18,  16, 18, 19,
  22, 21, 20,  23, 22, 20,
}
// odinfmt: enable
