shader_type canvas_item;

uniform float darkness : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float eyelid_amount : hint_range(0.0, 1.0) = 0.0;
uniform bool use_eyelids = false;

void fragment() {
	vec4 col = fade_color;
	col.a *= darkness;

	if (use_eyelids) {
		float edge = min(UV.y, 1.0 - UV.y) * 2.0;
		float threshold = mix(-0.15, 1.15, eyelid_amount);
		float lid = smoothstep(threshold - 0.15, threshold, edge);
		col.a = max(col.a, 1.0 - lid);
	}

	COLOR = col;
}