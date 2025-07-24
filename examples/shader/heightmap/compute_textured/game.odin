package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import sshape "sokol/shape"
import stm "sokol/time"

Game_Memory :: struct {
  camera:  Camera,
  pass:    sg.Pass_Action,
  //
  display: Entity,
  quad:    Entity,
  debug:   Entity,
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

  // display
  g.pass = {
    colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}},
  }

  vertices: [64 * 1024]f32
  indices: [64 * 1024]u16

  buf := sshape.Buffer {
    vertices = {buffer = {ptr = &vertices, size = size_of(vertices)}},
    indices = {buffer = {ptr = &indices, size = size_of(indices)}},
  }
  // plane
  buf = sshape.build_plane(
    buf,
    {width = TERRAIN_WIDTH, depth = TERRAIN_HEIGHT, tiles = TERRAIN_TILES},
  )
  g.display.draw = sshape.element_range(buf)
  g.display.bind.vertex_buffers[0] = sg.make_buffer(sshape.vertex_buffer_desc(buf))
  g.display.bind.index_buffer = sg.make_buffer(sshape.index_buffer_desc(buf))

  // quad
  buf = sshape.build_plane(
    buf,
    {
      width = 2,
      depth = 2,
      tiles = 1,
      transform = {
        m = transmute([4][4]f32)(linalg.matrix4_rotate_f32(90 * linalg.RAD_PER_DEG, {1, 0, 0})),
      },
    },
  )
  g.quad.draw = sshape.element_range(buf)
  g.quad.bind.vertex_buffers[0] = sg.make_buffer(sshape.vertex_buffer_desc(buf))
  g.quad.bind.index_buffer = sg.make_buffer(sshape.index_buffer_desc(buf))

  pipeline_desc := sg.Pipeline_Desc {
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

  g.display.pip = sg.make_pipeline(pipeline_desc)

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

  // quad
  quad_pip_desc := pipeline_desc
  quad_pip_desc.shader = sg.make_shader(quad_shader_desc(sg.query_backend()))
  g.quad.pip = sg.make_pipeline(quad_pip_desc)

  // debug
  debug_pip_desc := pipeline_desc
  debug_pip_desc.primitive_type = .LINE_STRIP
  g.debug.pip = sg.make_pipeline(debug_pip_desc)

  // compute
  compute_pipeline := sg.make_pipeline(
    {compute = true, shader = sg.make_shader(init_shader_desc(sg.query_backend()))},
  )
  sg.begin_pass({compute = true, attachments = attachments})
  sg.apply_pipeline(compute_pipeline)
  sg.dispatch(NOISE_WIDTH / 32, NOISE_HEIGHT / 32, 1)
  sg.end_pass()
  sg.destroy_pipeline(compute_pipeline)

  sampler := sg.make_sampler({})

  g.display.bind.images[IMG_heightmap_texture] = image_noise
  g.display.bind.samplers[SMP_heightmap_smp] = sampler

  g.display.bind.images[IMG_diffuse_texture] = image_diffuse
  g.display.bind.samplers[SMP_diffuse_smp] = sampler

  g.quad.bind.images[IMG_noise_texture] = image_diffuse
  g.quad.bind.samplers[SMP_noise_smp] = sampler
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

  sg.begin_pass({action = g.pass, swapchain = sglue.swapchain()})

  // plane
  sg.apply_pipeline(DEBUG_LINES ? g.debug.pip : g.display.pip)
  sg.apply_bindings(g.display.bind)
  sg.apply_uniforms(UB_vs_params, data = sg_range(&vs_params))
  sg.draw(g.display.draw.base_element, g.display.draw.num_elements, 1)

  debug_process()

  // quad
  sg.apply_pipeline(g.quad.pip)
  sg.apply_bindings(g.quad.bind)
  sg.apply_viewport(0, 0, QUAD_SIZE, QUAD_SIZE, false)
  sg.draw(g.quad.draw.base_element, g.quad.draw.num_elements, 1)

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
