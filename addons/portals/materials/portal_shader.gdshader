shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never;

uniform sampler2D albedo: hint_default_black, source_color;

void fragment() {
    vec3 portal_color = texture(albedo, SCREEN_UV).rgb;
    ALBEDO = portal_color;
    
    AO = 1.0;
    AO_LIGHT_AFFECT = 0.0;
}