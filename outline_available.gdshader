shader_type spatial;
render_mode unshaded, fog_disabled, cull_front, depth_draw_never;

uniform vec4 color : source_color = vec4(1,1,1,1);
uniform float thick = 0.2;

void vertex() {
	VERTEX += normalize(VERTEX) * (thick * 0.1);
}

void fragment() {
	ALBEDO = color.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
