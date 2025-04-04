package game

import "core:math"
import "core:math/linalg"

import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import stm "sokol/time"

@(export)
game_init :: proc() {
  g = new(Game_Memory)
  game_hot_reloaded(g)

  g.camera_pos = {0, 0, 30}
  g.camera_front = {0, 0, -1}
  g.camera_up = {0, 1, 0}
  g.first_mouse = true
  g.fov = 45
  g.yaw = -90

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  sapp.show_mouse(false)

  g.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(CUBE_VERTICES)})
  g.bind.index_buffer = sg.make_buffer({type = .INDEXBUFFER, data = sg_range(CUBE_INDICES)})

  img := load_image("assets/round_cat.png")
  g.bind.samplers[SMP_smp] = sg.make_sampler({})
  g.bind.images[IMG_tex] = sg.make_image(
    {
      width = i32(img.width),
      height = i32(img.height),
      data = {subimage = {0 = {0 = sg_range(img)}}},
    },
  )

  g.pip = sg.make_pipeline(
    {
      shader = sg.make_shader(simple_shader_desc(sg.query_backend())),
      layout = {
        attrs = {ATTR_simple_pos = {format = .FLOAT3}, ATTR_simple_uvs0 = {format = .FLOAT2}},
      },
      index_type = .UINT16,
      cull_mode = .BACK,
      depth = {compare = .LESS_EQUAL, write_enabled = true},
      // primitive_type = .LINES,
    },
  )

  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 1}}},
  }
}

cubes_pos :: [?]Vec3 {
  {1, 0, 0},
  {5, 0, 2},
  {0, 5, 2},
  {1, -3, 8},
  {0, 9, 3},
  {5, 2, 8},
  {-5, 0, 5},
  {-5, 2, -3},
  {4, 1, -7},
}

@(export)
game_frame :: proc() {
  g.delta_time = stm.laptime(&g.last_time)

  view := linalg.matrix4_look_at_f32(g.camera_pos, g.camera_pos + g.camera_front, g.camera_up)
  projection := linalg.matrix4_perspective_f32(g.fov, sapp.widthf() / sapp.heightf(), 0.1, 100.0)

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.pip)
  sg.apply_bindings(g.bind)

  vs_params := Vs_Params{{view = view, projection = projection}}

  for pos in cubes_pos {
    vs_params.model =
      linalg.matrix4_translate_f32(pos) *
      linalg.matrix4_rotate_f32(linalg.RAD_PER_DEG * -65 * f32(stm.sec(stm.now())), pos)

    sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))

    sg.draw(0, 36, 1)
  }

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}

SPEED :: 20
SENSITIVITY :: 0.005

@(export)
game_event :: proc(e: ^sapp.Event) {
  if e.type == .KEY_DOWN {
    if e.key_code == .R do force_reset = true
    if e.key_code == .Q do sapp.request_quit()

    camera_speed := SPEED * f32(stm.sec(g.delta_time))

    if e.key_code == .W {
      offset := g.camera_front * camera_speed
      g.camera_pos += offset
    }
    if e.key_code == .S {
      offset := g.camera_front * camera_speed
      g.camera_pos -= offset
    }
    if e.key_code == .A {
      offset := linalg.normalize(linalg.cross(g.camera_front, g.camera_up)) * camera_speed
      g.camera_pos -= offset
    }
    if e.key_code == .D {
      offset := linalg.normalize(linalg.cross(g.camera_front, g.camera_up)) * camera_speed
      g.camera_pos += offset
    }
  }

  if e.type == .MOUSE_MOVE {
    if g.first_mouse {
      g.last_x = e.mouse_x
      g.last_y = e.mouse_y
      g.first_mouse = false
    }

    xoffset := e.mouse_x - g.last_x
    yoffset := g.last_y - e.mouse_y
    g.last_x = e.mouse_x
    g.last_y = e.mouse_y

    xoffset *= SENSITIVITY
    yoffset *= SENSITIVITY

    g.yaw += linalg.to_degrees(xoffset)
    g.pitch += linalg.to_degrees(yoffset)

    if g.pitch > 89.0 do g.pitch = 89.0
    if g.pitch < -89.0 do g.pitch = -89.0

    direction: Vec3
    direction.x = math.cos(linalg.to_radians(g.yaw)) * math.cos(linalg.to_radians(g.pitch))
    direction.y = math.sin(linalg.to_radians(g.pitch))
    direction.z = math.sin(linalg.to_radians(g.yaw)) * math.cos(linalg.to_radians(g.pitch))
    g.camera_front = linalg.normalize(direction)
  }
}
