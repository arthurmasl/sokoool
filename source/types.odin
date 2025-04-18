package game

import sg "sokol/gfx"
import "vendor:cgltf"

Mesh :: struct {
  pipeline:      sg.Pipeline,
  bindings:      sg.Bindings,
  indices_count: uint,
  bones:         [50]Mat4,
}

Game_Memory :: struct {
  mesh:   Mesh,
  pass:   sg.Pass_Action,
  camera: Camera,
}

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
