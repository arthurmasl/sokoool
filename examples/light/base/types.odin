package game

import sg "sokol/gfx"

Game_Memory :: struct {
  pip_cube:    sg.Pipeline,
  pip_light:   sg.Pipeline,
  bind:        sg.Bindings,
  pass:        sg.Pass_Action,
  //
  camera:      Camera,
  //
  cube_pos:    Vec3,
  cube_color:  Vec3,
  //
  light_pos:   Vec3,
  light_color: Vec3,
}

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat4 :: matrix[4, 4]f32

TexturedVertex :: struct {
  pos: Vec3,
  uvs: Vec2,
}

Vertex :: struct {
  pos: Vec3,
}
