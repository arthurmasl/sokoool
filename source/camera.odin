package game

import "core:math"
import "core:math/linalg"

import sapp "sokol/app"

Camera :: struct {
  pos:         Vec3,
  front:       Vec3,
  up:          Vec3,
  //
  first_mouse: bool,
  mouse_x:     f32,
  mouse_y:     f32,
  yaw:         f32,
  pitch:       f32,
  fov:         f32,
  // 
  turbo:       bool,
  speed:       f32,
}

key_down: #sparse[sapp.Keycode]bool

SPEED :: 200
TURBO_SPEED :: 2000
SENSITIVITY :: 0.2

camera_init :: proc() {
  sapp.show_mouse(false)

  g.camera.first_mouse = true
  g.camera.pos = {0, 0, 0}
  g.camera.front = {0, 0, -1}
  g.camera.up = {0, 1, 0}
  g.camera.fov = 45
  g.camera.yaw = -90

  g.camera.speed = SPEED

  g.camera.pos = {4250, 3200, 1900}
  g.camera.pitch = -40
  g.camera.yaw = 90
}

camera_process_input :: proc(e: ^sapp.Event) {
  if e.type == .FOCUSED || e.type == .RESIZED do sapp.lock_mouse(true)
  if e.type == .UNFOCUSED do sapp.lock_mouse(false)

  if !sapp.mouse_locked() do return

  // keyboard
  if e.type == .KEY_DOWN do key_down[e.key_code] = true
  if e.type == .KEY_UP do key_down[e.key_code] = false

  if e.type == .KEY_DOWN && e.key_code == .T {
    g.camera.turbo = !g.camera.turbo
    g.camera.speed = g.camera.turbo ? TURBO_SPEED : SPEED
  }

  // mosue
  if e.type == .MOUSE_MOVE {
    if g.camera.first_mouse {
      g.camera.first_mouse = false
      return
    }

    g.camera.mouse_x = e.mouse_dx
    g.camera.mouse_y = e.mouse_dy
  }
}

@(require_results)
camera_update :: proc() -> (Mat4, Mat4) {
  // camera
  g.camera.yaw += g.camera.mouse_x * SENSITIVITY
  g.camera.pitch -= g.camera.mouse_y * SENSITIVITY

  g.camera.mouse_x = 0
  g.camera.mouse_y = 0

  g.camera.pitch = math.clamp(g.camera.pitch, -89, 89)

  direction := Vec3 {
    math.cos(linalg.to_radians(g.camera.yaw)) *
    math.cos(linalg.to_radians(g.camera.pitch)),
    math.sin(linalg.to_radians(g.camera.pitch)),
    math.sin(linalg.to_radians(g.camera.yaw)) *
    math.cos(linalg.to_radians(g.camera.pitch)),
  }

  g.camera.front = linalg.normalize(direction)

  // movement
  vel := g.camera.speed * delta_time
  dir := Vec3{}

  up := g.camera.up
  front := g.camera.front
  right := linalg.cross(g.camera.front, g.camera.up)

  if key_down[.E] do dir += front
  if key_down[.D] do dir -= front
  if key_down[.S] do dir -= right
  if key_down[.F] do dir += right

  if key_down[.SPACE] do dir += up
  if key_down[.Z] do dir -= up

  g.camera.pos += linalg.normalize0(dir) * vel
  // g.camera.pos.y = max(g.camera.pos.y, 1)

  view := linalg.matrix4_look_at_f32(
    g.camera.pos,
    g.camera.pos + g.camera.front,
    g.camera.up,
  )
  projection := linalg.matrix4_perspective_f32(
    g.camera.fov,
    sapp.widthf() / sapp.heightf(),
    0.1,
    25000.0,
  )

  return view, projection
}
