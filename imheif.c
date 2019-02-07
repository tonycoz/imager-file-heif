#include "imheif.h"
#include "libheif/heif.h"
#include "imext.h"
#include <errno.h>

#define START_SLURP_SIZE 8192
#define next_slurp_size(old) ((size_t)((old) * 3 / 2) + 10)

#if 0
static i_img *
get_image(WebPMux *mux, int n, int *error) {
  WebPMuxFrameInfo f;
  WebPMuxError err;
  WebPBitstreamFeatures feat;
  VP8StatusCode code;
  i_img *img;
  WebPMuxAnimParams anim;
#if IMAGER_API_VERSION * 0x100 + IMAGER_API_LEVEL >= 0x50A
  WebPData exif;
#endif

  *error = 0;
  if ((err = WebPMuxGetFrame(mux, n, &f)) != WEBP_MUX_OK) {
    if (err != WEBP_MUX_NOT_FOUND) {
      i_push_errorf(err, "failed to read %d", (int)err);
      *error = 1;
    }
    return NULL;
  }

  if ((code = WebPGetFeatures(f.bitstream.bytes, f.bitstream.size, &feat))
      != VP8_STATUS_OK) {
    WebPDataClear(&f.bitstream);
    i_push_errorf((int)code, "failed to get features (%d)", (int)code);
    return NULL;
  }

  if (!i_int_check_image_file_limits(feat.width, feat.height, feat.has_alpha ? 4 : 3, 1)) {
    *error = 1;
    WebPDataClear(&f.bitstream);
    return NULL;
  }

  if (feat.has_alpha) {
    int width, height;
    int y;
    uint8_t *bmp = WebPDecodeRGBA(f.bitstream.bytes, f.bitstream.size,
				 &width, &height);
    uint8_t *p = bmp;
    if (!bmp) {
      WebPDataClear(&f.bitstream);
      i_push_error(0, "failed to decode");
      *error = 1;
      return NULL;
    }
    img = i_img_8_new(width, height, 4);
    for (y = 0; y < height; ++y) {
      i_psamp(img, 0, width, y, p, NULL, 4);
      p += width * 4;
    }
    WebPFree(bmp);
  }
  else {
    int width, height;
    int y;
    uint8_t *bmp = WebPDecodeRGB(f.bitstream.bytes, f.bitstream.size,
				 &width, &height);
    uint8_t *p = bmp;
    if (!bmp) {
      WebPDataClear(&f.bitstream);
      i_push_error(0, "failed to decode");
      *error = 1;
      return NULL;
    }
    img = i_img_8_new(width, height, 3);
    for (y = 0; y < height; ++y) {
      i_psamp(img, 0, width, y, p, NULL, 3);
      p += width * 3;
    }
    WebPFree(bmp);
  }

  if (find_fourcc(&f.bitstream, "VP8L", NULL)) {
    i_tags_set(&img->tags, "webp_mode", "lossless", 8);
  }
  else {
    i_tags_set(&img->tags, "webp_mode", "lossy", 5);
  }
  i_tags_setn(&img->tags, "webp_left", f.x_offset);
  i_tags_setn(&img->tags, "webp_top", f.y_offset);
  i_tags_setn(&img->tags, "webp_duration", f.duration);
  if (f.dispose_method == WEBP_MUX_DISPOSE_NONE)
    i_tags_set(&img->tags, "webp_dispose", "none", -1);
  else
    i_tags_set(&img->tags, "webp_dispose", "background", -1);
  if (f.blend_method == WEBP_MUX_BLEND)
    i_tags_set(&img->tags, "webp_blend", "alpha", -1);
  else
    i_tags_set(&img->tags, "webp_blend", "none", -1);

  if (WebPMuxGetAnimationParams(mux, &anim) == WEBP_MUX_OK) {
    union color_u32 {
      i_color c;
      uint32_t n;
    } color;
    i_tags_setn(&img->tags, "webp_loop_count", anim.loop_count);
    color.n = anim.bgcolor;
    i_tags_set_color(&img->tags, "webp_background", 0, &color.c);
  }

#if IMAGER_API_VERSION * 0x100 + IMAGER_API_LEVEL >= 0x50A
  if (WebPMuxGetChunk(mux, "EXIF", &exif) == WEBP_MUX_OK) {
    im_decode_exif(exif.bytes, exif.size);
  }
#endif
  
  WebPDataClear(&f.bitstream);

  i_tags_set(&img->tags, "i_format", "webp", 4);
  
  return img;
}

#endif

i_img *
i_readheif(io_glue *ig, int page) {
#if 1
  return NULL;
#else
  WebPMux *mux;
  i_img *img;
  unsigned char *mdata;
  WebPData data;
  int n;
  int imgs_alloc = 0;
  int error;

  i_clear_error();
  if (page < 0) {
    i_push_error(0, "page must be non-negative");
    return NULL;
  }

  data.bytes = mdata = slurpio(ig, &data.size);
  
  mux = WebPMuxCreate(&data, 0);

  if (!mux) {
    myfree(mdata);
    i_push_error(0, "Cannot create mux object.  Bad file?");
    return NULL;
  }

  img = get_image(mux, page+1, &error);
  if (img == NULL && !error) {
    i_push_error(0, "No such image");
  }

  WebPMuxDelete(mux);
  myfree(mdata);
  
  return img;
#endif
}

i_img **
i_readheif_multi(io_glue *ig, int *count) {
#if 1
  return NULL;
#else
  WebPMux *mux;
  i_img *img;
  unsigned char *mdata;
  WebPData data;
  int n;
  i_img **result = NULL;
  int imgs_alloc = 0;
  int error;

  data.bytes = mdata = slurpio(ig, &data.size);
  
  mux = WebPMuxCreate(&data, 0);

  if (!mux) {
    myfree(mdata);
    i_push_error(0, "Cannot create mux object.  ABI mismatch?");
    return NULL;
  }

  n = 1;
  img = get_image(mux, n++, &error);
  *count = 0;
  while (img) {
    if (*count == imgs_alloc) {
      imgs_alloc += 10;
      result = myrealloc(result, imgs_alloc * sizeof(i_img *));
    }
    result[(*count)++] = img;
    img = get_image(mux, n++, &error);
  }

  if (error) {
    while (*count) {
      --*count;
      i_img_destroy(result[*count]);
    }
    myfree(result);
    goto fail;
  }
  else if (*count == 0) {
    i_push_error(0, "No images found");
  }

  WebPMuxDelete(mux);
  myfree(mdata);
  
  return result;

 fail:
  WebPMuxDelete(mux);
  myfree(mdata);
  return NULL;
#endif
}

undef_int
i_writeheif(i_img *im, io_glue *ig) {
  return i_writeheif_multi(ig, &im, 1);
}

#if 0

static const int gray_chans[4] = { 0, 0, 0, 1 };

static unsigned char *
frame_raw(i_img *im, int *out_chans) {
  unsigned char *data, *p;
  i_img_dim y;
  const int *chans = im->channels < 3 ? gray_chans : NULL;
  *out_chans = (im->channels & 1) ? 3 : 4;
  data = mymalloc(im->xsize * im->ysize * *out_chans);
  p = data;
  for (y = 0; y < im->ysize; ++y) {
    i_gsamp(im, 0, im->xsize, y, p, chans, *out_chans);
    p += *out_chans * im->xsize;
  }

  return data;
}

static unsigned char *
frame_webp(i_img *im, size_t *sz) {
  int chans;
  unsigned char *raw = frame_raw(im, &chans);
  uint8_t *webp;
  size_t webp_size;
  char webp_mode[80];
  int lossy = 1;

  if (i_tags_get_string(&im->tags, "webp_mode", 0, webp_mode, sizeof(webp_mode))) {
    if (strcmp(webp_mode, "lossless") == 0) {
      lossy = 0;
    }
    else if (strcmp(webp_mode, "lossy") != 0) {
      i_push_error(0, "webp_mode must be 'lossy' or 'lossless'");
      return NULL;
    }
  }
  if (lossy) {
    double quality;
    if (i_tags_get_float(&im->tags, "webp_quality", 0, &quality)) {
      if (quality < 0 || quality > 100) {
	i_push_error(0, "webp_quality must be in the range 0 to 100 inclusive");
	return NULL;
      }
    }
    else {
      quality = 80;
    }
    if (chans == 4) {
      webp_size = WebPEncodeRGBA(raw, im->xsize, im->ysize, im->xsize * chans, quality, &webp);
    }
    else {
      webp_size = WebPEncodeRGB(raw, im->xsize, im->ysize, im->xsize * chans, quality, &webp);
    }
  }
  else {
    if (chans == 4) {
      webp_size = WebPEncodeLosslessRGBA(raw, im->xsize, im->ysize, im->xsize * chans, &webp);
    }
    else {
      webp_size = WebPEncodeLosslessRGB(raw, im->xsize, im->ysize, im->xsize * chans, &webp);
    }
  }
  *sz = webp_size;
  myfree(raw);
  return webp;
}

#endif

undef_int
i_writeheif_multi(io_glue *ig, i_img **imgs, int count) {
#if 1
  return 0;
#else
  WebPMux *mux;
  int i;
  WebPData outd;
  WebPMuxError err;

  if (count == 0) {
    i_push_error(0, "must be at least one image");
    return 0;
  }

  for (i = 0; i < count; ++i) {
    if (imgs[i]->xsize > 16383) {
      i_push_error(0, "maximum webp image width is 16383");
      return 0;
    }
    if (imgs[i]->ysize > 16383) {
      i_push_error(0, "maximum webp image height is 16383");
      return 0;
    }
  }

  mux = WebPMuxNew();

  if (!mux) {
    i_push_error(0, "Cannot create mux object.  ABI mismatch?");
    return 0;
  }

  if (count == 1) {
    WebPData d;
    d.bytes = frame_webp(imgs[0], &d.size);
    if (!d.bytes)
      goto fail;

    if ((err = WebPMuxSetImage(mux, &d, 1)) != WEBP_MUX_OK) {
      i_push_errorf(err, "failed to set image (%d)", (int)err);
      WebPDataClear(&d);
      goto fail;
    }
    WebPDataClear(&d);
  }
  else {
    WebPMuxFrameInfo f;
    WebPMuxAnimParams params = { 0xFFFFFFFF, 0 };
    union {
      i_color c;
      uint32_t n;
    } color;

    if (!i_tags_get_int(&imgs[0]->tags, "webp_loop_count", 0,
			&params.loop_count)) {
      params.loop_count = 0;
    }
    if (i_tags_get_color(&imgs[0]->tags, "webp_background", 0,
			&color.c)) {
      params.bgcolor = color.n;
    }
    f.id = WEBP_CHUNK_ANMF;
    for (i = 0; i < count; ++i) {
      WebPData d;
      char buf[80];

      if (!i_tags_get_int(&imgs[i]->tags, "webp_left", 0, &f.x_offset))
	f.x_offset = 0;
      if (!i_tags_get_int(&imgs[i]->tags, "webp_top", 0, &f.y_offset))
	f.y_offset = 0;
      if (!i_tags_get_int(&imgs[i]->tags, "webp_duration", 0, &f.duration))
	f.duration = 100;
      if (i_tags_get_string(&imgs[i]->tags, "webp_dispose", 0, buf, sizeof(buf))) {
	if (strcmp(buf, "none") == 0) {
	  f.dispose_method = WEBP_MUX_DISPOSE_NONE;
	}
	else if (strcmp(buf, "background") == 0) {
	  f.dispose_method = WEBP_MUX_DISPOSE_BACKGROUND;
	}
	else {
	  i_push_error(0, "invalid webp_dispose, must be 'none' or 'background'");
	  goto fail;
	}
      }
      else {
	f.dispose_method = WEBP_MUX_DISPOSE_BACKGROUND;
      }
      
      if (i_tags_get_string(&imgs[i]->tags, "webp_blend", 0, buf, sizeof(buf))) {
	if (strcmp(buf, "alpha") == 0) {
	  f.blend_method = WEBP_MUX_BLEND;
	}
	else if (strcmp(buf, "none") == 0) {
	  f.blend_method = WEBP_MUX_NO_BLEND;
	}
	else {
	  i_push_error(0, "invalid webp_blend, must be 'none' or 'alpha'");
	  goto fail;
	}
      }
      else {
	f.blend_method = WEBP_MUX_BLEND;
      }
      
      f.bitstream.bytes = frame_webp(imgs[i], &f.bitstream.size);
      if (!f.bitstream.bytes)
	goto fail;

      WebPMuxPushFrame(mux, &f, 1);
      WebPDataClear(&f.bitstream);
    }
    err = WebPMuxSetAnimationParams(mux, &params);
    if (err != WEBP_MUX_OK) {
      i_push_errorf((int)err, "failed to set animation params (%d)", (int)err);
      goto fail;
    }
  }

  if ((err = WebPMuxAssemble(mux, &outd)) != WEBP_MUX_OK) {
    i_push_errorf((int)err, "failed to assemble %d", (int)err);
    goto fail;
  }

  if (i_io_write(ig, outd.bytes, outd.size) != outd.size) {
    i_push_error(errno, "failed to write");
    WebPDataClear(&outd);
    goto fail;
  }
  WebPDataClear(&outd);

  if (i_io_close(ig))
    goto fail;

  WebPMuxDelete(mux);
  return 1;

 fail:
  WebPMuxDelete(mux);
  return 0;
#endif
}

char const *
i_heif_libversion(void) {
  static char buf[100];
  if (!*buf) {
    unsigned int ver = heif_get_version_number();
    sprintf(buf, "%d.%d.%d (%x)",
	    ver >> 24, (ver >> 16) & 0xFF, (ver >> 8) & 0xFF);
  }
  return buf;
}
