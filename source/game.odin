package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import sshape "sokol/shape"
import stm "sokol/time"

Game_Memory :: struct {
  camera:    Camera,
  //
  ranges:    [BindingID]sshape.Element_Range,
  passes:    [PassID]sg.Pass,
  bindings:  [BindingID]sg.Bindings,
  pipelines: [PipelineID]sg.Pipeline,
}

QUAD_SIZE :: 500

NOISE_WIDTH :: 128
NOISE_HEIGHT :: 128

TERRAIN_WIDTH :: 12800.0
TERRAIN_HEIGHT :: 12800.0
TERRAIN_TILES :: 100

TRIANGLES :: TERRAIN_TILES * 2 * 4

@(export)
game_init :: proc() {
  if g == nil {
    g = new(Game_Memory)
    game_hot_reloaded(g)
    camera_init()
  }

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  // resources
  display_pip_desc := sg.Pipeline_Desc {
    shader = sg.make_shader(base_shader_desc(sg.query_backend())),
    layout = {
      buffers = {0 = sshape.vertex_buffer_layout_state()},
      attrs = {
        0 = sshape.position_vertex_attr_state(),
        1 = sshape.normal_vertex_attr_state(),
        2 = sshape.texcoord_vertex_attr_state(),
        3 = sshape.color_vertex_attr_state(),
      },
    },
    index_type = .UINT16,
    cull_mode = .BACK,
    depth = {compare = .LESS_EQUAL, write_enabled = true},
  }

  quad_pip_desc := display_pip_desc
  quad_pip_desc.shader = sg.make_shader(quad_shader_desc(sg.query_backend()))

  debug_pip_desc := display_pip_desc
  debug_pip_desc.primitive_type = .LINE_STRIP

  sampler := sg.make_sampler({})
  image_desc := sg.Image_Desc {
    type = ._2D,
    width = NOISE_WIDTH,
    height = NOISE_HEIGHT,
    usage = {storage_attachment = true},
    pixel_format = .RGBA32F,
  }
  image_noise := sg.make_image(image_desc)
  image_diffuse := sg.make_image(image_desc)

  attachments := sg.make_attachments(
    {
      storages = {
        SIMG_noise_image = {image = image_noise},
        SIMG_diffuse_image = {image = image_diffuse},
      },
    },
  )

  atlas_transform := transmute([4][4]f32)(linalg.matrix4_rotate_f32(
      90 * linalg.RAD_PER_DEG,
      {1, 0, 0},
    ))

  // passes
  g.passes[.Display] = {
    action = {colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}}},
  }
  g.passes[.Compute] = {
    compute     = true,
    attachments = attachments,
  }

  // shapes
  build_shape(
    .Terrain,
    sshape.Plane{width = TERRAIN_WIDTH, depth = TERRAIN_HEIGHT, tiles = TERRAIN_TILES},
  )
  build_shape(
    .Atlas,
    sshape.Plane{width = 2, depth = 2, tiles = 1, transform = {m = atlas_transform}},
  )

  // pipelines
  g.pipelines[.Display] = sg.make_pipeline(display_pip_desc)
  g.pipelines[.Atlas] = sg.make_pipeline(quad_pip_desc)
  g.pipelines[.Primitive] = sg.make_pipeline(debug_pip_desc)
  g.pipelines[.Compute] = sg.make_pipeline(
    {compute = true, shader = sg.make_shader(init_shader_desc(sg.query_backend()))},
  )

  // compute
  sg.begin_pass(g.passes[.Compute])
  sg.apply_pipeline(g.pipelines[.Compute])
  sg.dispatch(NOISE_WIDTH / 32, NOISE_HEIGHT / 32, 1)
  sg.end_pass()
  sg.destroy_pipeline(g.pipelines[.Compute])

  // images
  g.bindings[.Terrain].images[IMG_heightmap_texture] = image_noise
  g.bindings[.Terrain].images[IMG_diffuse_texture] = image_diffuse
  g.bindings[.Atlas].images[IMG_noise_texture] = image_diffuse

  // samplers
  g.bindings[.Terrain].samplers[SMP_heightmap_smp] = sampler
  g.bindings[.Terrain].samplers[SMP_diffuse_smp] = sampler
  g.bindings[.Atlas].samplers[SMP_noise_smp] = sampler
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  time := f32(stm.sec(stm.now()))
  model := linalg.matrix4_translate_f32({0, -500, 0})

  vs_params := Vs_Params {
    mvp         = projection * view * model,
    u_time      = time,
    u_light_dir = Vec3{0, 1.0, 0},
  }

  sg.begin_pass({action = g.passes[.Display].action, swapchain = sglue.swapchain()})

  // terrain
  sg.apply_pipeline(DEBUG_LINES ? g.pipelines[.Primitive] : g.pipelines[.Display])
  sg.apply_bindings(g.bindings[.Terrain])
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(g.ranges[.Terrain].base_element, g.ranges[.Terrain].num_elements, 1)

  // debug screen
  sg.apply_pipeline(g.pipelines[.Atlas])
  sg.apply_bindings(g.bindings[.Atlas])
  sg.apply_viewport(0, 0, QUAD_SIZE, QUAD_SIZE, false)
  sg.draw(g.ranges[.Atlas].base_element, g.ranges[.Atlas].num_elements, 1)

  debug_process()

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
