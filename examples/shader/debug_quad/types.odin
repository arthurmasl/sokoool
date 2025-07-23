package game

import sg "sokol/gfx"
import sshape "sokol/shape"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat3 :: matrix[3, 3]f32
Mat4 :: matrix[4, 4]f32

Vertex :: struct {
  position: Vec3,
  normal:   Vec3,
  texcoord: Vec2,
}

Entity :: struct {
  pip:  sg.Pipeline,
  bind: sg.Bindings,
  draw: sshape.Element_Range,
}
