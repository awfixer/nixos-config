precision highp float;

#if defined(DEBUG_FLAGS)
uniform float awm_tint;
#endif

varying vec2 awm_v_coords;
uniform vec2 awm_size;

uniform mat3 awm_input_to_geo;
uniform vec2 awm_geo_size;

uniform sampler2D awm_tex;
uniform mat3 awm_geo_to_tex;

uniform float awm_progress;
uniform float awm_clamped_progress;
uniform float awm_random_seed;

uniform float awm_alpha;
uniform float awm_scale;

