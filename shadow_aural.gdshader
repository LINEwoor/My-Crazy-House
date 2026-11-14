shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, depth_draw_never, fog_disabled;

uniform vec4 ink_color : source_color = vec4(0.05, 0.05, 0.08, 1.0);
uniform float outline_width = 0.02;
uniform float noise_scale = 18.0;
uniform float tear_amount = 0.5;
uniform float redraw_rate = 9.0;

uniform float pulse_amp : hint_range(0.0, 0.5) = 0.015;
uniform float pulse_speed : hint_range(0.0, 20.0) = 1.5;
uniform float pulse_noise_scale : hint_range(0.5, 40.0) = 6.0;

float hash(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float noise(vec3 p) {
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(hash(i), hash(i+vec3(1,0,0)), f.x),
            mix(hash(i+vec3(0,1,0)), hash(i+vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(i+vec3(0,0,1)), hash(i+vec3(1,0,1)), f.x),
            mix(hash(i+vec3(0,1,1)), hash(i+vec3(1,1,1)), f.x), f.y),
        f.z);
}

void vertex() {
    vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    float n = noise(wp * pulse_noise_scale + vec3(0.0, TIME * pulse_speed, TIME * pulse_speed * 0.7));

    float pulse = (n - 0.5) * 2.0 * pulse_amp;

    float offset = outline_width + pulse;
    VERTEX += normalize(VERTEX) * offset;
}

void fragment() {
    float t = (redraw_rate > 0.001) ? floor(TIME * redraw_rate) / redraw_rate : 0.0;
    vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float nz = noise(wp * noise_scale + vec3(0.0, t * 7.0, t * 3.0));
    if (nz < tear_amount) discard;
    ALBEDO = ink_color.rgb;
    ALPHA = 1.0;
}