#define PERL_NO_GET_CONTEXT
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"
#include "imheif.h"

DEFINE_IMAGER_CALLBACKS;

static int
max_threads(pTHX) {
  SV *sv = get_sv("Imager::File::HEIF::MaxThreads", 0);
  if (sv && (SvGETMAGIC(sv), SvOK(sv))) {
    return SvIV(sv);
  }
  else {
    return -1;
  }
}

#define i_heif_context_CLONE_SKIP()

typedef struct heif_context *Imager__File__HEIF__Context;
typedef struct heif_encoder_descriptor *Imager__File__HEIF__EncoderDescriptor;
typedef struct heif_encoder *Imager__File__HEIF__Encoder;

#define i_heif_context() xi_heif_context(aTHX)
PERL_STATIC_INLINE struct heif_context *
xi_heif_context(pTHX) {
    struct heif_context *ctx = heif_context_alloc();
    if (!ctx)
        croak("Cannot create HEIF context");
    return ctx;
}

void
i_heif_context_DESTROY(struct heif_context *ctx) {
    heif_context_free(ctx);
}

static struct compression_names_t {
  enum heif_compression_format fmt;
  const char *name;
} compression_names[] =
{
  { heif_compression_undefined, "undefined" },
  { heif_compression_HEVC, "hevc" },
  { heif_compression_AVC, "avc" },
  { heif_compression_JPEG, "jpeg" },
  { heif_compression_AV1, "av1" },
  { heif_compression_VVC, "vvc" },
  { heif_compression_EVC, "evc" },
  { heif_compression_JPEG2000, "jpeg2000" },
  { heif_compression_uncompressed, "uncompressed" },
  { heif_compression_mask, "mask" },
  { heif_compression_HTJ2K, "jpeg2000ht" },
};

static const size_t compression_name_count =
    sizeof(compression_names) / sizeof(compression_names[0]);

static enum heif_compression_format
xi_heif_compression_format(pTHX_ const char *name) {
    int i;
    for (i = 0; i < compression_name_count; ++i) {
        if (strcmp(compression_names[i].name, name) == 0) {
            return compression_names[i].fmt;
        }
    }
    croak("unknown HEIF compression type '%s'", name);
}


MODULE = Imager::File::HEIF  PACKAGE = Imager::File::HEIF

TYPEMAP: <<HERE
Imager::File::HEIF::Context	T_PTROBJ
Imager::File::HEIF::EncoderDescriptor  T_PTROBJ
Imager::File::HEIF::Encoder  T_PTROBJ
enum heif_compression_format T_COMP_FORMAT

INPUT
T_COMP_FORMAT
    $var = xi_heif_compression_format(aTHX_ SvPV_nolen($arg));

HERE

PROTOTYPES: DISABLE

Imager::ImgRaw
i_readheif(ig, page=0)
        Imager::IO     ig
               int     page
  C_ARGS: ig, page, max_threads(aTHX)

void
i_readheif_multi(ig)
        Imager::IO     ig
      PREINIT:
        i_img **imgs;
        int count;
        int i;
      PPCODE:
        imgs = i_readheif_multi(ig, &count, max_threads(aTHX));
        if (imgs) {
          EXTEND(SP, count);
          for (i = 0; i < count; ++i) {
            SV *sv = sv_newmortal();
            sv_setref_pv(sv, "Imager::ImgRaw", (void *)imgs[i]);
            PUSHs(sv);
          }
          myfree(imgs);
        }


undef_int
i_writeheif(im, ig)
    Imager::ImgRaw     im
        Imager::IO     ig

undef_int
i_writeheif_multi(ig, ...)
        Imager::IO     ig
      PREINIT:
        int i;
        int img_count;
        i_img **imgs;
      CODE:
        if (items < 2)
          croak("Usage: i_writeheif_multi(ig, images...)");
        img_count = items - 1;
        RETVAL = 1;
	if (img_count < 1) {
	  RETVAL = 0;
	  i_clear_error();
	  i_push_error(0, "You need to specify images to save");
	}
	else {
          imgs = mymalloc(sizeof(i_img *) * img_count);
          for (i = 0; i < img_count; ++i) {
	    SV *sv = ST(1+i);
	    imgs[i] = NULL;
	    if (SvROK(sv) && sv_derived_from(sv, "Imager::ImgRaw")) {
	      imgs[i] = INT2PTR(i_img *, SvIV((SV*)SvRV(sv)));
	    }
	    else {
	      i_clear_error();
	      i_push_error(0, "Only images can be saved");
              myfree(imgs);
	      RETVAL = 0;
	      break;
            }
	  }
          if (RETVAL) {
	    RETVAL = i_writeheif_multi(ig, imgs, img_count);
          }
	  myfree(imgs);
	}
      OUTPUT:
        RETVAL


MODULE = Imager::File::HEIF  PACKAGE = Imager::File::HEIF PREFIX = i_heif_

void
i_heif_dump_encoders(class)
          C_ARGS:

const char *
i_heif_libversion(class)
          C_ARGS:

const char *
i_heif_buildversion(class)
          C_ARGS:

void
i_heif_init(class)
          C_ARGS:

void
i_heif_deinit(class)
          C_ARGS:

Imager::File::HEIF::Context
i_heif_context(class)
    C_ARGS:

void
i_heif_encoder_descriptors(class, enum heif_compression_format fmt = heif_compression_undefined)
  PREINIT:
    const struct heif_encoder_descriptor **descs = NULL;
    int count;
    int i;
  PPCODE:
    count = heif_get_encoder_descriptors(fmt, NULL, NULL, 0);
    Newx(descs, count, const struct heif_encoder_descriptor *);
    SAVEFREEPV(descs);
    heif_get_encoder_descriptors(fmt, NULL, descs, count);
    EXTEND(SP, count);
    for (i = 0; i < count; ++i) {
        SV *sv = sv_newmortal();
        sv_setref_pv(sv, "Imager::File::HEIF::EncoderDescriptor",
            (void *)descs[i]);
        PUSHs(sv);
    }
    

MODULE = Imager::File::HEIF  PACKAGE = Imager::File::HEIF::Context PREFIX = i_heif_context_

void
i_heif_context_DESTROY(Imager::File::HEIF::Context ctx)

void
i_heif_context_CLONE_SKIP(...)
  CODE:

MODULE = Imager::File::HEIF  PACKAGE = Imager::File::HEIF::EncoderDescriptor PREFIX = heif_encoder_descriptor_

const char *
heif_encoder_descriptor_get_id_name(Imager::File::HEIF::EncoderDescriptor enc)

const char *
heif_encoder_descriptor_get_name(Imager::File::HEIF::EncoderDescriptor enc)

void
i_heif_encdesc_CLONE_SKIP(...)
  CODE:

# no need for DESTROY

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;
        i_heif_init();
