package game

import sg "sokol/gfx"

Mat4 :: matrix[4, 4]f32

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

// Vertex :: struct {
//   x, y, z: f32,
//   color:   u32,
//   u, v:    u16,
// }

Vertex :: struct {
  pos:            Vec3,
  color:          sg.Color,
  texture_coords: Vec2,
}
