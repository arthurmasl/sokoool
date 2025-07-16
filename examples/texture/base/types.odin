package game

import sg "sokol/gfx"

Mat4 :: matrix[4, 4]f32

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Vertex :: struct {
  pos:   Vec3,
  color: sg.Color,
  uvs:   Vec2,
}
