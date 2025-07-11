package game

s :: 1.0
z :: 0.0

// odinfmt: disable
QUAD_VERTICES := []f32 {
  // pos   // texcoord
  -s,  s,  z, s,
  -s, -s,  z, z,
   s, -s,  s, z,
              
  -s,  s,  z, s,
   s, -s,  s, z,
   s,  s,  s, s,
}
// odinfmt: enable
