package game

CUBE_NORMAL_VERTICES :: []struct {
  pos:       Vec3,
  normal:    Vec3,
  texcoords: Vec2,
} {
  // Front face (+Z)
  {pos = {-0.5, -0.5, 0.5}, normal = {0, 0, 1}, texcoords = {1, 1}},
  {pos = {0.5, -0.5, 0.5}, normal = {0, 0, 1}, texcoords = {0, 1}},
  {pos = {0.5, 0.5, 0.5}, normal = {0, 0, 1}, texcoords = {0, 0}},
  {pos = {-0.5, 0.5, 0.5}, normal = {0, 0, 1}, texcoords = {1, 0}},

  // Back face (-Z)
  {pos = {-0.5, -0.5, -0.5}, normal = {0, 0, -1}},
  {pos = {0.5, -0.5, -0.5}, normal = {0, 0, -1}},
  {pos = {0.5, 0.5, -0.5}, normal = {0, 0, -1}},
  {pos = {-0.5, 0.5, -0.5}, normal = {0, 0, -1}},

  // Left face (-X)
  {pos = {-0.5, -0.5, -0.5}, normal = {-1, 0, 0}, texcoords = {1, 1}},
  {pos = {-0.5, 0.5, -0.5}, normal = {-1, 0, 0}, texcoords = {0, 1}},
  {pos = {-0.5, 0.5, 0.5}, normal = {-1, 0, 0}, texcoords = {0, 0}},
  {pos = {-0.5, -0.5, 0.5}, normal = {-1, 0, 0}, texcoords = {1, 0}},

  // Right face (+X)
  {pos = {0.5, -0.5, -0.5}, normal = {1, 0, 0}},
  {pos = {0.5, 0.5, -0.5}, normal = {1, 0, 0}},
  {pos = {0.5, 0.5, 0.5}, normal = {1, 0, 0}},
  {pos = {0.5, -0.5, 0.5}, normal = {1, 0, 0}},

  // Bottom face (-Y)
  {pos = {-0.5, -0.5, -0.5}, normal = {0, -1, 0}},
  {pos = {-0.5, -0.5, 0.5}, normal = {0, -1, 0}},
  {pos = {0.5, -0.5, 0.5}, normal = {0, -1, 0}},
  {pos = {0.5, -0.5, -0.5}, normal = {0, -1, 0}},

  // Top face (+Y)
  {pos = {-0.5, 0.5, -0.5}, normal = {0, 1, 0}, texcoords = {1, 1}},
  {pos = {-0.5, 0.5, 0.5}, normal = {0, 1, 0}, texcoords = {0, 1}},
  {pos = {0.5, 0.5, 0.5}, normal = {0, 1, 0}, texcoords = {0, 0}},
  {pos = {0.5, 0.5, -0.5}, normal = {0, 1, 0}, texcoords = {1, 0}},
}

// odinfmt: disable
CUBE_INDICES := []u16 {
  0, 1, 2,  0, 2, 3,
  6, 5, 4,  7, 6, 4,
  8, 9, 10,  8, 10, 11,
  14, 13, 12,  15, 14, 12,
  16, 17, 18,  16, 18, 19,
  22, 21, 20,  23, 22, 20,
}
// odinfmt: enable
