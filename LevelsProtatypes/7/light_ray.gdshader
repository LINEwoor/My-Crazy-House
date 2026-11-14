shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 beam_color : source_color = vec4(1.0, 0.9, 0.6, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 3.0;

uniform float fade_power : hint_range(0.1, 8.0) = 4.0;
uniform float fade_strength : hint_range(0.1, 4.0) = 2.0;
uniform float start_fade : hint_range(0.0, 0.5) = 0.05;
uniform float end_fade : hint_range(0.0, 0.5) = 0.0;

uniform float edge_softness : hint_range(0.0, 1.0) = 0.5;
uniform float edge_power : hint_range(0.1, 8.0) = 2.0;

uniform float distance_fade_min : hint_range(0.0, 100.0) = 10.0;
uniform float distance_fade_max : hint_range(0.0, 100.0) = 15.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float proximity_fade_distance : hint_range(0.0, 5.0) = 0.1;

const vec3 ign = vec3(0.06711056, 0.00583715, 52.9829189);

void fragment() {
    float along = 1.0 - UV.y;

    float length_fade = pow(along, fade_power);
    length_fade = pow(length_fade, fade_strength);
    float soft_start = smoothstep(0.0, start_fade, along);
    float soft_end   = smoothstep(1.0 - end_fade, 1.0, along);
    length_fade *= soft_start * (1.0 - soft_end * 0.5);

    float across = abs(UV.x - 0.5) * 2.0;              // 0 в центре, 1 на краю
    float across_fade = 1.0 - smoothstep(1.0 - edge_softness, 1.0, across);
    across_fade = pow(across_fade, edge_power);

    float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
    float normal_fade = pow(facing, edge_power);

    float camera_dist = length(VERTEX);
    float fade_progress = smoothstep(distance_fade_min, distance_fade_max, camera_dist);
    float noise = fract(ign.z * fract(dot(FRAGCOORD.xy, ign.xy)));
    if (noise < fade_progress * dither_strength) {
        discard;
    }

    float scene_depth = texture(depth_texture, SCREEN_UV).r;
    vec4 scene_view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_depth, 1.0);
    scene_view_pos.xyz /= scene_view_pos.w;

    float depth_diff = VERTEX.z - scene_view_pos.z;
    float proximity_fade = smoothstep(0.0, proximity_fade_distance, depth_diff);

    float alpha = length_fade * across_fade * normal_fade * intensity * proximity_fade;

    ALBEDO = beam_color.rgb * intensity;
    ALPHA = clamp(alpha, 0.0, 1.0);
}