package game

import "base:intrinsics"
import "core:fmt"
import "core:image/png"
import "core:log"
import "core:os"
import sg "sokol/gfx"
import stbi "vendor:stb/image"

import "web"

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

load_png_image :: proc(name: string) -> ^png.Image {
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

load_image :: proc(name: string) -> sg.Image_Desc {
  path := fmt.tprintf("assets/%s", name)
  img_data, img_data_ok := read_entire_file(path, context.temp_allocator)
  if !img_data_ok do panic("Failed loading texture")

  width, height, channels: i32
  desired_channels := i32(4)

  pixels := stbi.load_from_memory(
    &img_data[0],
    i32(len(img_data)),
    &width,
    &height,
    &channels,
    desired_channels,
  )
  if pixels == nil do panic("Failed to load texture")
  defer stbi.image_free(pixels)

  return {
    width = i32(width),
    height = i32(height),
    pixel_format = .RGBA8,
    data = {subimage = {0 = {0 = {ptr = pixels, size = uint(width * height * desired_channels)}}}},
  }
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
    return {ptr = raw_data(st.pixels.buf), size = uint(st.width * st.height * 4)}
  }

  return {ptr = st, size = size_of(T)}
}
