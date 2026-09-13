precision highp float;

#if defined(DEBUG_FLAGS)
uniform float awm_tint;
#endif

varying vec2 awm_v_coords;
uniform vec2 awm_size;

uniform mat3 awm_input_to_curr_geo;
uniform mat3 awm_curr_geo_to_prev_geo;
uniform mat3 awm_curr_geo_to_next_geo;
uniform vec2 awm_curr_geo_size;

uniform sampler2D awm_tex_prev;
uniform mat3 awm_geo_to_tex_prev;

uniform sampler2D awm_tex_next;
uniform mat3 awm_geo_to_tex_next;

uniform float awm_progress;
uniform float awm_clamped_progress;

uniform vec4 awm_corner_radius;
uniform float awm_clip_to_geometry;

uniform float awm_alpha;
uniform float awm_scale;

float awm_rounding_alpha(vec2 coords, vec2 size, vec4 corner_radius);
