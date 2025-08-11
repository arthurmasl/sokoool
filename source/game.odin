package game

import "core:math/linalg"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"
import sshape "sokol/shape"
import stm "sokol/time"

Game_Memory :: struct {
  camera:     Camera,
  //
  ranges:     [BindingID]sshape.Element_Range,
  passes:     [PassID]sg.Pass,
  bindings:   [BindingID]sg.Bindings,
  pipelines:  [PipelineID]sg.Pipeline,
  //
  grass_inst: [GRASS_COUNT]Grass_Sb_Instance,
}

QUAD_SIZE :: 500
NOISE_SIZE :: 100
COMPUTE_THREADS :: 1
GRID_TILES :: 100
GRID_SCALE :: 10

NUM_TERRAIN_VERTICES :: (GRID_TILES + COMPUTE_THREADS) * (GRID_TILES + COMPUTE_THREADS)
NUM_TERRAIN_INDICES :: GRID_TILES * GRID_TILES * 6

GRASS_COUNT :: 100000
GRASS_CHUNK_SIZE :: GRID_TILES * GRID_SCALE

@(export)
game_init :: proc() {
  if g == nil {
    g = new(Game_Memory)
    game_hot_reloaded(g)
    camera_init()
  }

  read_config()

  sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
  stm.setup()
  debug_init()

  // resources
  default_pip_desc := sg.Pipeline_Desc {
    shader = sg.make_shader(terrain_shader_desc(sg.query_backend())),
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

  sampler := sg.make_sampler({})
  image_desc := sg.Image_Desc {
    type = ._2D,
    width = NOISE_SIZE,
    height = NOISE_SIZE,
    usage = {storage_attachment = true},
    pixel_format = .RGBA32F,
  }
  image_noise := sg.make_image(image_desc)
  image_diffuse := sg.make_image(image_desc)

  attachments := sg.make_attachments(
    {
      storages = {
        SIMG_terrain_compute_noise_image = {image = image_noise},
        SIMG_terrain_compute_diffuse_image = {image = image_diffuse},
      },
    },
  )

  // passes
  g.passes[.Display] = {
    action = {colors = {0 = {load_action = .CLEAR, clear_value = {0.2, 0.2, 0.2, 1.0}}}},
  }
  g.passes[.Compute] = {
    compute     = true,
    attachments = attachments,
  }

  // terrain
  terrain_pip_desc := sg.Pipeline_Desc {
    shader = sg.make_shader(terrain_shader_desc(sg.query_backend())),
    cull_mode = .FRONT,
    index_type = .UINT16,
    depth = {compare = .LESS_EQUAL, write_enabled = true},
  }
  g.pipelines[.Terrain] = sg.make_pipeline(terrain_pip_desc)

  terrain_storage_buffer := sg.make_buffer(
    {
      usage = {storage_buffer = true},
      size = size_of(Terrain_Sb_Vertex) * NUM_TERRAIN_VERTICES,
    },
  )
  g.bindings[.Terrain].storage_buffers = {
    SBUF_terrain_vertices_buffer = terrain_storage_buffer,
  }
  terrain_indices := build_indices(NUM_TERRAIN_INDICES, GRID_TILES)
  defer delete(terrain_indices)
  g.bindings[.Terrain].index_buffer = sg.make_buffer(
    {usage = {index_buffer = true}, data = sg_range(terrain_indices)},
  )

  // primitive
  debug_pip_desc := terrain_pip_desc
  debug_pip_desc.primitive_type = .LINE_STRIP
  g.pipelines[.Primitive] = sg.make_pipeline(debug_pip_desc)

  // grass
  grass_pip_desc := sg.Pipeline_Desc {
    shader = sg.make_shader(grass_shader_desc(sg.query_backend())),
    index_type = .UINT16,
    cull_mode = .NONE,
    depth = {compare = .LESS_EQUAL, write_enabled = true},
    // primitive_type = .LINE_STRIP,
  }
  g.pipelines[.Grass] = sg.make_pipeline(grass_pip_desc)

  grass_storage_buffer := sg.make_buffer(
    {usage = {storage_buffer = true}, size = size_of(Grass_Sb_Instance) * GRASS_COUNT},
  )
  build_grass(.Grass, grass_storage_buffer)

  // g.bindings[.Grass].images[IMG_heightmap_texture_g] = image_noise
  // g.bindings[.Grass].samplers[SMP_heightmap_smp_g] = sampler

  // atlas
  quad_pip_desc := default_pip_desc
  quad_pip_desc.shader = sg.make_shader(quad_shader_desc(sg.query_backend()))
  g.pipelines[.Atlas] = sg.make_pipeline(quad_pip_desc)

  atlas_transform := transmute([4][4]f32)(linalg.matrix4_rotate_f32(
      90 * linalg.RAD_PER_DEG,
      {1, 0, 0},
    ))
  build_shape(
    .Atlas,
    sshape.Plane{width = 2, depth = 2, tiles = 1, transform = {m = atlas_transform}},
  )

  g.bindings[.Atlas].images[IMG_quad_noise_texture] = image_diffuse
  g.bindings[.Atlas].samplers[SMP_quad_noise_smp] = sampler

  // compute
  compute_params := Grass_Compute_Vs_Params {
    grid_tiles = GRID_TILES,
    grid_scale = GRID_SCALE,
  }

  // compute terrain
  g.pipelines[.Terrain_Compute] = sg.make_pipeline(
    {
      compute = true,
      shader = sg.make_shader(terrain_compute_shader_desc(sg.query_backend())),
    },
  )
  g.bindings[.Terrain_Compute].storage_buffers = {
    SBUF_terrain_compute_terrain_buffer = terrain_storage_buffer,
  }

  sg.begin_pass(g.passes[.Compute])
  sg.apply_pipeline(g.pipelines[.Terrain_Compute])
  sg.apply_bindings(g.bindings[.Terrain_Compute])
  sg.apply_uniforms(UB_terrain_compute_vs_params, sg_range(&compute_params))
  sg.dispatch(GRID_TILES + 1, GRID_TILES + 1, 1)
  sg.end_pass()
  sg.destroy_pipeline(g.pipelines[.Terrain_Compute])

  // compute grass
  g.pipelines[.Grass_Compute] = sg.make_pipeline(
    {
      compute = true,
      shader = sg.make_shader(grass_compute_shader_desc(sg.query_backend())),
    },
  )
  g.bindings[.Grass_Compute].storage_buffers = {
    SBUF_grass_compute_grass_buffer = grass_storage_buffer,
  }

  sg.begin_pass(g.passes[.Compute])
  sg.apply_pipeline(g.pipelines[.Grass_Compute])
  sg.apply_bindings(g.bindings[.Grass_Compute])
  sg.apply_uniforms(UB_grass_compute_vs_params, sg_range(&compute_params))
  sg.dispatch(GRID_TILES + 1, GRID_TILES + 1, 1)
  sg.end_pass()
  sg.destroy_pipeline(g.pipelines[.Grass_Compute])
}

@(export)
game_frame :: proc() {
  delta_time = f32(sapp.frame_duration())

  view, projection := camera_update()
  time := f32(stm.sec(stm.now()))

  vs_params := Terrain_Vs_Params {
    mvp         = projection * view * linalg.matrix4_translate_f32({0, 0, 0}),
    u_time      = time,
    u_light_dir = Vec3{0.0, 1.0, 0.0},
  }
  vs_params_grass := Grass_Vs_Params {
    vp          = projection * view,
    u_time      = vs_params.u_time,
    u_light_dir = vs_params.u_light_dir,
  }

  sg.begin_pass({action = g.passes[.Display].action, swapchain = sglue.swapchain()})

  // terrain
  sg.apply_pipeline(DEBUG_LINES ? g.pipelines[.Primitive] : g.pipelines[.Terrain])
  sg.apply_bindings(g.bindings[.Terrain])
  sg.apply_uniforms(UB_terrain_vs_params, data = sg_range(&vs_params))
  sg.draw(0, NUM_TERRAIN_INDICES, 1)

  // grass
  sg.apply_pipeline(g.pipelines[.Grass])
  sg.apply_bindings(g.bindings[.Grass])
  sg.apply_uniforms(UB_grass_vs_params, data = sg_range(&vs_params_grass))
  sg.draw(g.ranges[.Grass].base_element, g.ranges[.Grass].num_elements, GRASS_COUNT)

  // debug screen
  sg.apply_viewport(0, 0, QUAD_SIZE, QUAD_SIZE, false)
  sg.apply_pipeline(g.pipelines[.Atlas])
  sg.apply_bindings(g.bindings[.Atlas])
  sg.draw(g.ranges[.Atlas].base_element, g.ranges[.Atlas].num_elements, 1)

  debug_process()

  sg.end_pass()
  sg.commit()

  free_all(context.temp_allocator)
}
