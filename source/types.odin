package game

import sg "sokol/gfx"

Game_Memory :: struct {
  pip:       sg.Pipeline,
  bind:      sg.Bindings,
  pass:      sg.Pass_Action,
  last_time: u64,
}

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat4 :: matrix[4, 4]f32

Vertex :: struct {
  pos: Vec3,
  uvs: Vec2,
}
