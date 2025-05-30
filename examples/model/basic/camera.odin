package game

import "core:math"
import "core:math/linalg"

import sapp "sokol/app"

Camera :: struct {
  pos:           Vec3,
  front:         Vec3,
  up:            Vec3,
  //
  first_mouse:   bool,
  yaw:           f32,
  pitch:         f32,
  fov:           f32,
  //
  held_forward:  bool,
  held_backward: bool,
  held_left:     bool,
  held_right:    bool,
  held_up:       bool,
  held_down:     bool,
}

SPEED :: 10
SENSITIVITY :: 0.2

camera_init :: proc() {
  sapp.show_mouse(false)

  g.camera.first_mouse = true
  g.camera.pos = {0, 0, 10}
  g.camera.front = {0, 0, -1}
  g.camera.up = {0, 1, 0}
  g.camera.fov = 45
  g.camera.yaw = -90

}

camera_process_input :: proc(e: ^sapp.Event) {
  if e.type == .FOCUSED || e.type == .RESIZED do sapp.lock_mouse(true)
  if e.type == .UNFOCUSED do sapp.lock_mouse(false)

  if !sapp.mouse_locked() do return

  // keyboard
  if e.type == .KEY_DOWN {
    if e.key_code == .E do g.camera.held_forward = true
    if e.key_code == .D do g.camera.held_backward = true
    if e.key_code == .S do g.camera.held_left = true
    if e.key_code == .F do g.camera.held_right = true

    if e.key_code == .SPACE do g.camera.held_up = true
    if e.key_code == .Z do g.camera.held_down = true
  }

  if e.type == .KEY_UP {
    if e.key_code == .E do g.camera.held_forward = false
    if e.key_code == .D do g.camera.held_backward = false
    if e.key_code == .S do g.camera.held_left = false
    if e.key_code == .F do g.camera.held_right = false

    if e.key_code == .SPACE do g.camera.held_up = false
    if e.key_code == .Z do g.camera.held_down = false
  }

  // mosue
  if e.type == .MOUSE_MOVE {
    if g.camera.first_mouse {
      g.camera.first_mouse = false
      return
    }

    g.camera.yaw += e.mouse_dx * SENSITIVITY
    g.camera.pitch -= e.mouse_dy * SENSITIVITY

    if g.camera.pitch > 89.0 do g.camera.pitch = 89.0
    if g.camera.pitch < -89.0 do g.camera.pitch = -89.0

    direction := Vec3 {
      math.cos(linalg.to_radians(g.camera.yaw)) * math.cos(linalg.to_radians(g.camera.pitch)),
      math.sin(linalg.to_radians(g.camera.pitch)),
      math.sin(linalg.to_radians(g.camera.yaw)) * math.cos(linalg.to_radians(g.camera.pitch)),
    }

    g.camera.front = linalg.normalize(direction)

  }
}

camera_update :: proc() -> (Mat4, Mat4) {
  vel := SPEED * delta_time
  dir := Vec3{}

  up := g.camera.up
  front := g.camera.front
  right := linalg.cross(g.camera.front, g.camera.up)

  if g.camera.held_forward do dir += front
  if g.camera.held_backward do dir -= front
  if g.camera.held_left do dir -= right
  if g.camera.held_right do dir += right

  if g.camera.held_up do dir += up
  if g.camera.held_down do dir -= up

  g.camera.pos += linalg.normalize0(dir) * vel
  g.camera.pos.y = max(g.camera.pos.y, 0)

  view := linalg.matrix4_look_at_f32(g.camera.pos, g.camera.pos + g.camera.front, g.camera.up)
  projection := linalg.matrix4_perspective_f32(
    g.camera.fov,
    sapp.widthf() / sapp.heightf(),
    0.1,
    1000.0,
  )

  return view, projection
}
