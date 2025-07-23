package game

// odinfmt: disable
QUAD_VERTICES := []f32 {
  // pos        // uv
  -1,  1, 1,    0, 1,
   1,  1, 1,    1, 1,
   1, -1, 1,    1, 0,
  -1, -1, 1,    0, 0,
}

QUAD_INDICES := []u16 {
  0,1,2,
  0,2,3,
}
// odinfmt: enable
