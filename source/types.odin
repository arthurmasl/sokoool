package game

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat3 :: matrix[3, 3]f32
Mat4 :: matrix[4, 4]f32

BindingID :: enum u8 {
  Cube,
  Terrain,
  Shadow,
}

PipelineID :: enum u8 {
  Display,
  Primitive,
  Shadow,
}

PassID :: enum u8 {
  Display,
  Shadow,
}
