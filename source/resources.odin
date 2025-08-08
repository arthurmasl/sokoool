package game

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
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

write_entire_file :: proc(
  name: string,
  data: []byte,
  truncate := true,
) -> (
  success: bool,
) {
  when IS_WEB {
    return web.write_entire_file(name, data, truncate)
  } else {
    return os.write_entire_file(name, data, truncate)
  }
}

CONFIG_SRC :: "settings.config"

Param_Id :: enum {
  Pos,
  Yaw,
  Pitch,
  Turbo,
  Debug_Text,
  Debug_Lines,
  Debug_Camera,
}

write_config :: proc() {
  params_array := [Param_Id]any {
    .Pos          = g.camera.pos,
    .Yaw          = g.camera.yaw,
    .Pitch        = g.camera.pitch,
    .Turbo        = g.camera.turbo,
    .Debug_Text   = DEBUG_TEXT,
    .Debug_Lines  = DEBUG_LINES,
    .Debug_Camera = DEBUG_CAMERA,
  }

  config: string
  for value, key in params_array {
    config = strings.join(
      []string {
        config,
        fmt.aprintf("%v: %v\n", key, value, allocator = context.temp_allocator),
      },
      "",
      allocator = context.temp_allocator,
    )
  }

  write_entire_file(CONFIG_SRC, transmute([]byte)config)
}

read_config :: proc() {
  config, success := read_entire_file(CONFIG_SRC, context.temp_allocator)
  if !success do write_config()

  str := strings.split(transmute(string)config, "\n", context.temp_allocator)

  for line in str[:len(str) - 1] {
    values := strings.split(line, ": ", context.temp_allocator)
    name := values[0]
    value := values[1]

    switch name {
    case "Pos":
      value = value[1:len(value) - 1]
      args := strings.split(value, ", ", context.temp_allocator)

      g.camera.pos = Vec3 {
        f32(strconv.atoi(args[0])),
        f32(strconv.atoi(args[1])),
        f32(strconv.atoi(args[2])),
      }
    case "Pitch":
      g.camera.pitch = f32(strconv.atoi(value))

    case "Yaw":
      g.camera.yaw = f32(strconv.atoi(value))

    case "Turbo":
      set_turbo(value == "true")

    case "Debug_Text":
      DEBUG_TEXT = value == "true"
    case "Debug_Lines":
      DEBUG_LINES = value == "true"
    case "Debug_Camera":
      DEBUG_CAMERA = value == "true"

    }
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

@(require_results)
sg_range_from_slice :: proc(sl: []$T) -> sg.Range {
  return {ptr = raw_data(sl), size = uint(slice.size(sl))}
}

@(require_results)
sg_range_from_struct :: proc(st: ^$T) -> sg.Range where intrinsics.type_is_struct(T) {
  return sg.Range{ptr = st, size = size_of(T)}
}
