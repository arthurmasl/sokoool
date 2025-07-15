package game

import "core:fmt"

import sapp "sokol/app"
import sdtx "sokol/debugtext"
import sg "sokol/gfx"
import sgl "sokol/gl"
import mu "vendor:microui"

DEBUG_TEXT := false

Debug_UI :: struct {
  pip:             sgl.Pipeline,
  mu_ctx:          mu.Context,
  log_buf:         [1 << 16]byte,
  log_buf_len:     int,
  log_buf_updated: bool,
  bg:              mu.Color,
  atlas_img:       sg.Image,
  atlas_smp:       sg.Sampler,
}

debug_init :: proc() {
  // sdtx.setup({fonts = {0 = sdtx.font_oric()}, logger = {func = slog.func}})

  sgl.setup({})

  pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
  for alpha, i in mu.default_atlas_alpha {
    pixels[i].rgb = 0xff
    pixels[i].a = alpha
  }

  g.debug.atlas_img = sg.make_image(
    sg.Image_Desc {
      width = mu.DEFAULT_ATLAS_WIDTH,
      height = mu.DEFAULT_ATLAS_HEIGHT,
      data = {
        subimage = {
          0 = {
            0 = {
              ptr = raw_data(pixels),
              size = mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT * 4,
            },
          },
        },
      },
    },
  )

  g.debug.atlas_smp = sg.make_sampler(
    sg.Sampler_Desc{min_filter = .NEAREST, mag_filter = .NEAREST},
  )

  g.debug.pip = sgl.make_pipeline(
    sg.Pipeline_Desc {
      colors = {
        0 = {
          blend = {
            enabled = true,
            src_factor_rgb = .SRC_ALPHA,
            dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
          },
        },
      },
    },
  )

  ctx := &g.debug.mu_ctx
  mu.init(ctx)

  free(&pixels)
}

debug_process :: proc() {
  if !DEBUG_TEXT do return

  sdtx.canvas(sapp.widthf() / 4, sapp.heightf() / 4)
  sdtx.origin(1, 1)

  fps := 1.0 / delta_time
  print_text("FPS: %d", u8(fps))

  print_text("CAMERA: %#w", g.camera)

  sdtx.draw()
}

print_text :: proc(format: string, args: ..any) {
  sdtx.puts(fmt.ctprintf(format, ..args, newline = true))
  sdtx.move_y(0.5)
}
