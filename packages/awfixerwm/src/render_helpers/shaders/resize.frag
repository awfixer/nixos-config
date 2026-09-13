vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
    vec3 coords_tex_prev = awm_geo_to_tex_prev * coords_curr_geo;
    vec4 color_prev = texture2D(awm_tex_prev, coords_tex_prev.st);

    vec3 coords_tex_next = awm_geo_to_tex_next * coords_curr_geo;
    vec4 color_next = texture2D(awm_tex_next, coords_tex_next.st);

    vec4 color = mix(color_prev, color_next, awm_clamped_progress);
    return color;
}
