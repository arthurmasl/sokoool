package game

import "core:math"
import "core:math/linalg"

import sapp "sokol/app"

Camera :: struct {
  pos:    Vec3,
  front:  Vec3,
  up:     Vec3,
  //
  last_x: f32,
  last_y: f32,
  yaw:    f32,
  pitch:  f32,
  fov:    f32,
  //
  init:   bool,
}

FREE_CAMERA := true

SPEED :: 30
SENSITIVITY :: 0.005

camera_init :: proc() {
  sapp.show_mouse(false)

  g.camera.pos = {0, 0, 10}
  g.camera.front = {0, 0, -1}
  g.camera.up = {0, 1, 0}
  g.camera.init = true
  g.camera.fov = 45
  g.camera.yaw = -90

}

camera_update :: proc() -> (Mat4, Mat4) {
  view := linalg.matrix4_look_at_f32(g.camera.pos, g.camera.pos + g.camera.front, g.camera.up)
  projection := linalg.matrix4_perspective_f32(
    g.camera.fov,
    sapp.widthf() / sapp.heightf(),
    0.1,
    100.0,
  )

  return view, projection
}

camera_process_input :: proc(e: ^sapp.Event) {
  if !FREE_CAMERA do return

  // keyboard
  if e.type == .KEY_DOWN {
    camera_speed := SPEED * delta_time

    if e.key_code == .E {
      offset := g.camera.front * camera_speed
      g.camera.pos += offset
    }
    if e.key_code == .D {
      offset := g.camera.front * camera_speed
      g.camera.pos -= offset
    }
    if e.key_code == .S {
      offset := linalg.normalize(linalg.cross(g.camera.front, g.camera.up)) * camera_speed
      g.camera.pos -= offset
    }
    if e.key_code == .F {
      offset := linalg.normalize(linalg.cross(g.camera.front, g.camera.up)) * camera_speed
      g.camera.pos += offset
    }

    if e.key_code == .SPACE {
      offset := g.camera.up * camera_speed
      g.camera.pos += offset
    }
    if e.key_code == .C {
      offset := g.camera.up * camera_speed
      g.camera.pos -= offset
    }
  }

  // mosue
  if e.type == .MOUSE_MOVE {
    if g.camera.init {
      g.camera.last_x = e.mouse_x
      g.camera.last_y = e.mouse_y
      g.camera.init = false
    }

    xoffset := e.mouse_x - g.camera.last_x
    yoffset := g.camera.last_y - e.mouse_y
    g.camera.last_x = e.mouse_x
    g.camera.last_y = e.mouse_y

    xoffset *= SENSITIVITY
    yoffset *= SENSITIVITY

    g.camera.yaw += linalg.to_degrees(xoffset)
    g.camera.pitch += linalg.to_degrees(yoffset)

    if g.camera.pitch > 89.0 do g.camera.pitch = 89.0
    if g.camera.pitch < -89.0 do g.camera.pitch = -89.0

    direction: Vec3
    direction.x =
      math.cos(linalg.to_radians(g.camera.yaw)) * math.cos(linalg.to_radians(g.camera.pitch))
    direction.y = math.sin(linalg.to_radians(g.camera.pitch))
    direction.z =
      math.sin(linalg.to_radians(g.camera.yaw)) * math.cos(linalg.to_radians(g.camera.pitch))
    g.camera.front = linalg.normalize(direction)
  }
}
