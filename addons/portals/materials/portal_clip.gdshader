shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;

#include "res://addons/portals/materials/portalclip_mesh.gdshaderinc"

PORTALCLIP_UNIFORMS

void vertex() {
	PORTALCLIP_VERTEX
}

void fragment() {
	ALBEDO = albedo_color.rgb * texture(albedo_texture, UV).rgb;

	PORTALCLIP_FRAGMENT
}