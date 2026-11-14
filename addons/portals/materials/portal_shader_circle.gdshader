shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo: hint_default_black, source_color;

uniform float dissolve_amount : hint_range(-0.5, 1.5) = 0.0;
uniform float edge_width : hint_range(0.01, 0.2) = 0.06;
uniform vec3 edge_color_1 : source_color = vec3(0.2, 0.5, 2.0);
uniform vec3 edge_color_2 : source_color = vec3(1.0, 0.2, 0.0);

uniform float noise_scale = 4.0;
uniform float noise_speed = 1.5;
uniform float noise_strength = 0.5;
uniform float edge_glow_intensity = 5.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec3 portal_color = texture(albedo, SCREEN_UV).rgb;

    float dist = distance(UV, vec2(0.5));
    
    vec2 animated_uv = UV * noise_scale + vec2(TIME * noise_speed * 0.7, TIME * noise_speed * 0.4);
    float turbulence = fbm(animated_uv + TIME * 0.5);
    float final_noise = fbm(animated_uv + turbulence * 0.5);

    float circle_mask = (0.5 - dist - (final_noise - 0.5) * noise_strength) * 2.0;

    if (circle_mask < dissolve_amount) {
        discard;
    }

    float edge_gradient = 1.0 - smoothstep(dissolve_amount, dissolve_amount + edge_width, circle_mask);
    
    float hot_edge = smoothstep(0.0, 0.5, edge_gradient);
    vec3 final_edge_color = mix(edge_color_2, edge_color_1, hot_edge);

    vec3 final_color = mix(portal_color, final_edge_color, edge_gradient);

    ALBEDO = final_color;
    
    EMISSION = final_edge_color * edge_gradient * edge_glow_intensity;
}