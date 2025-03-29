package game

import "core:math/linalg"

import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"

@(export)
game_frame :: proc() {
  dt := f32(sapp.frame_duration())
  g.rx += 60 * dt
  g.ry += 120 * dt

  // vertex shader uniform with model-view-projection matrix
  vs_params := Vs_Params {
    mvp = compute_mvp(g.rx, g.ry),
  }

  pass_action := sg.Pass_Action {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.41, 0.68, 0.83, 1}}},
  }

  sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
  sg.apply_pipeline(g.pip)
  sg.apply_bindings(g.bind)
  sg.apply_uniforms(UB_vs_params, {ptr = &vs_params, size = size_of(vs_params)})

  // 36 is the number of indices
  sg.draw(0, 36, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}

compute_mvp :: proc(rx, ry: f32) -> Mat4 {
  proj := linalg.matrix4_perspective(60.0 * linalg.RAD_PER_DEG, sapp.widthf() / sapp.heightf(), 0.01, 10.0)
  view := linalg.matrix4_look_at_f32({0.0, -1.5, -6.0}, {}, {0.0, 1.0, 0.0})
  view_proj := proj * view
  rxm := linalg.matrix4_rotate_f32(rx * linalg.RAD_PER_DEG, {1.0, 0.0, 0.0})
  rym := linalg.matrix4_rotate_f32(ry * linalg.RAD_PER_DEG, {0.0, 1.0, 0.0})
  model := rxm * rym
  return view_proj * model
}
