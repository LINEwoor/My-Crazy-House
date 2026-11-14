shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, blend_mix;

uniform sampler2D albedo : hint_default_black, source_color;
uniform float portal_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec3 portal_color = texture(albedo, SCREEN_UV).rgb;

    ALBEDO = portal_color;
    ALPHA = portal_alpha;

    AO = 1.0;
    AO_LIGHT_AFFECT = 0.0;
}