package game

CUBE_UVS_VERTICES :: []struct {
  pos: Vec3,
  uvs: Vec2,
} {
  {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {1.0, -1.0, -1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, -1.0}, uvs = {1, 1}},
  {pos = {-1.0, 1.0, -1.0}, uvs = {0, 1}},
  {pos = {-1.0, -1.0, 1.0}, uvs = {0, 0}},
  {pos = {1.0, -1.0, 1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {-1.0, 1.0, 1.0}, uvs = {0, 1}},
  {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {-1.0, 1.0, -1.0}, uvs = {1, 0}},
  {pos = {-1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {-1.0, -1.0, 1.0}, uvs = {0, 1}},
  {pos = {1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {1.0, 1.0, -1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {1.0, -1.0, 1.0}, uvs = {0, 1}},
  {pos = {-1.0, -1.0, -1.0}, uvs = {0, 0}},
  {pos = {-1.0, -1.0, 1.0}, uvs = {1, 0}},
  {pos = {1.0, -1.0, 1.0}, uvs = {1, 1}},
  {pos = {1.0, -1.0, -1.0}, uvs = {0, 1}},
  {pos = {-1.0, 1.0, -1.0}, uvs = {0, 0}},
  {pos = {-1.0, 1.0, 1.0}, uvs = {1, 0}},
  {pos = {1.0, 1.0, 1.0}, uvs = {1, 1}},
  {pos = {1.0, 1.0, -1.0}, uvs = {0, 1}},
}

CUBE_VERTICES :: []struct {
  pos: Vec3,
} {
  {pos = {-1.0, -1.0, -1.0}},
  {pos = {1.0, -1.0, -1.0}},
  {pos = {1.0, 1.0, -1.0}},
  {pos = {-1.0, 1.0, -1.0}},
  {pos = {-1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, 1.0}},
  {pos = {1.0, 1.0, 1.0}},
  {pos = {-1.0, 1.0, 1.0}},
  {pos = {-1.0, -1.0, -1.0}},
  {pos = {-1.0, 1.0, -1.0}},
  {pos = {-1.0, 1.0, 1.0}},
  {pos = {-1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, -1.0}},
  {pos = {1.0, 1.0, -1.0}},
  {pos = {1.0, 1.0, 1.0}},
  {pos = {1.0, -1.0, 1.0}},
  {pos = {-1.0, -1.0, -1.0}},
  {pos = {-1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, 1.0}},
  {pos = {1.0, -1.0, -1.0}},
  {pos = {-1.0, 1.0, -1.0}},
  {pos = {-1.0, 1.0, 1.0}},
  {pos = {1.0, 1.0, 1.0}},
  {pos = {1.0, 1.0, -1.0}},
}

CUBE_NORMAL_VERTICES :: []struct {
  pos:     Vec3,
  normals: Vec3,
} {
  {pos = {-0.5, -0.5, -0.5}, normals = {0.0, 0.0, -1.0}},
  {pos = {0.5, -0.5, -0.5}, normals = {0.0, 0.0, -1.0}},
  {pos = {0.5, 0.5, -0.5}, normals = {0.0, 0.0, -1.0}},
  {pos = {0.5, 0.5, -0.5}, normals = {0.0, 0.0, -1.0}},
  {pos = {-0.5, 0.5, -0.5}, normals = {0.0, 0.0, -1.0}},
  {pos = {-0.5, -0.5, -0.5}, normals = {0.0, 0.0, -1.0}},
  {pos = {-0.5, -0.5, 0.5}, normals = {0.0, 0.0, 1.0}},
  {pos = {0.5, -0.5, 0.5}, normals = {0.0, 0.0, 1.0}},
  {pos = {0.5, 0.5, 0.5}, normals = {0.0, 0.0, 1.0}},
  {pos = {0.5, 0.5, 0.5}, normals = {0.0, 0.0, 1.0}},
  {pos = {-0.5, 0.5, 0.5}, normals = {0.0, 0.0, 1.0}},
  {pos = {-0.5, -0.5, 0.5}, normals = {0.0, 0.0, 1.0}},
  {pos = {-0.5, 0.5, 0.5}, normals = {-1.0, 0.0, 0.0}},
  {pos = {-0.5, 0.5, -0.5}, normals = {-1.0, 0.0, 0.0}},
  {pos = {-0.5, -0.5, -0.5}, normals = {-1.0, 0.0, 0.0}},
  {pos = {-0.5, -0.5, -0.5}, normals = {-1.0, 0.0, 0.0}},
  {pos = {-0.5, -0.5, 0.5}, normals = {-1.0, 0.0, 0.0}},
  {pos = {-0.5, 0.5, 0.5}, normals = {-1.0, 0.0, 0.0}},
  {pos = {0.5, 0.5, 0.5}, normals = {1.0, 0.0, 0.0}},
  {pos = {0.5, 0.5, -0.5}, normals = {1.0, 0.0, 0.0}},
  {pos = {0.5, -0.5, -0.5}, normals = {1.0, 0.0, 0.0}},
  {pos = {0.5, -0.5, -0.5}, normals = {1.0, 0.0, 0.0}},
  {pos = {0.5, -0.5, 0.5}, normals = {1.0, 0.0, 0.0}},
  {pos = {0.5, 0.5, 0.5}, normals = {1.0, 0.0, 0.0}},
  {pos = {-0.5, -0.5, -0.5}, normals = {0.0, -1.0, 0.0}},
  {pos = {0.5, -0.5, -0.5}, normals = {0.0, -1.0, 0.0}},
  {pos = {0.5, -0.5, 0.5}, normals = {0.0, -1.0, 0.0}},
  {pos = {0.5, -0.5, 0.5}, normals = {0.0, -1.0, 0.0}},
  {pos = {-0.5, -0.5, 0.5}, normals = {0.0, -1.0, 0.0}},
  {pos = {-0.5, -0.5, -0.5}, normals = {0.0, -1.0, 0.0}},
  {pos = {-0.5, 0.5, -0.5}, normals = {0.0, 1.0, 0.0}},
  {pos = {0.5, 0.5, -0.5}, normals = {0.0, 1.0, 0.0}},
  {pos = {0.5, 0.5, 0.5}, normals = {0.0, 1.0, 0.0}},
  {pos = {0.5, 0.5, 0.5}, normals = {0.0, 1.0, 0.0}},
  {pos = {-0.5, 0.5, 0.5}, normals = {0.0, 1.0, 0.0}},
  {pos = {-0.5, 0.5, -0.5}, normals = {0.0, 1.0, 0.0}},
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
