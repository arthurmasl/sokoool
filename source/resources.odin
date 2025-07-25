package game

import "base:intrinsics"
import "core:fmt"
import "core:os"
import sg "sokol/gfx"
import stbi "vendor:stb/image"

import "web"
_, _ :: os, web

IS_WEB :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

@(require_results)
read_entire_file :: proc(
  name: string,
  allocator := context.allocator,
) -> (
  data: []byte,
  success: bool,
) {
  when IS_WEB {
    return web.read_entire_file(name, allocator)
  } else {
    return os.read_entire_file(name, allocator)
  }
}

load_image :: proc(name: string) -> sg.Image_Desc {
  stbi.set_flip_vertically_on_load(1)

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
    data = {
      subimage = {
        0 = {0 = {ptr = pixels, size = uint(width * height * desired_channels)}},
      },
    },
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
  return sg.Range{ptr = st, size = size_of(T)}
}
