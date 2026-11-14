shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, blend_mix, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float base_alpha : hint_range(0.0, 1.0) = 0.25;
uniform float edge_alpha : hint_range(0.0, 1.0) = 0.6;
uniform float fresnel_power : hint_range(1.0, 6.0) = 2.5;

// --- Диагональные линии ---
uniform float line_density : hint_range(1.0, 200.0) = 40.0;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.15;
uniform float line_speed : hint_range(-5.0, 5.0) = 0.3;
uniform float line_width : hint_range(0.0, 1.0) = 0.5;
uniform float line_angle : hint_range(0.0, 1.0) = 0.25;

void fragment() {
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

    float alpha = mix(base_alpha, edge_alpha, fresnel);

    float diag = SCREEN_UV.x + SCREEN_UV.y * (1.0 / max(line_angle, 0.001) - 1.0);
    float line_phase = diag * line_density + TIME * line_speed;
    float line = step(1.0 - line_width, fract(line_phase));

    vec3 col = base_color.rgb + fresnel * 0.3;
    col += line * 0.1;
    alpha = clamp(alpha + line * line_alpha, 0.0, 1.0);

    ALBEDO = col;
    ALPHA = alpha;
}