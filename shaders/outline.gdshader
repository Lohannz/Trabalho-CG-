shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float shadow_thickness : hint_range(0.0, 5.0) = 2.0;
uniform float sensitivity : hint_range(0.001, 0.5) = 0.01;

uniform float normal_sensitivity : hint_range(0.001, 1.0) = 0.15;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_linear;

float get_linear_depth(vec2 uv, mat4 proj_matrix) {
	float depth = texture(DEPTH_TEXTURE, uv).r;

	vec3 ndc = vec3(
		uv * 2.0 - 1.0,
		depth
	);

	vec4 view = proj_matrix * vec4(ndc, 1.0);

	view.xyz /= view.w;

	return -view.z;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 screen_size = vec2(textureSize(DEPTH_TEXTURE, 0));
	vec2 uv = SCREEN_UV;

	vec2 offset = shadow_thickness / screen_size;

	float depth_center =
		get_linear_depth(uv, INV_PROJECTION_MATRIX);

	float x = 0.0;
	float y = 0.0;

	// Sobel X
	x += get_linear_depth(
		uv + vec2(-offset.x, -offset.y),
		INV_PROJECTION_MATRIX
	) * -1.0;

	x += get_linear_depth(
		uv + vec2(-offset.x, 0.0),
		INV_PROJECTION_MATRIX
	) * -2.0;

	x += get_linear_depth(
		uv + vec2(-offset.x, offset.y),
		INV_PROJECTION_MATRIX
	) * -1.0;

	x += get_linear_depth(
		uv + vec2(offset.x, -offset.y),
		INV_PROJECTION_MATRIX
	) * 1.0;

	x += get_linear_depth(
		uv + vec2(offset.x, 0.0),
		INV_PROJECTION_MATRIX
	) * 2.0;

	x += get_linear_depth(
		uv + vec2(offset.x, offset.y),
		INV_PROJECTION_MATRIX
	) * 1.0;

	// Sobel Y
	y += get_linear_depth(
		uv + vec2(-offset.x, -offset.y),
		INV_PROJECTION_MATRIX
	) * -1.0;

	y += get_linear_depth(
		uv + vec2(0.0, -offset.y),
		INV_PROJECTION_MATRIX
	) * -2.0;

	y += get_linear_depth(
		uv + vec2(offset.x, -offset.y),
		INV_PROJECTION_MATRIX
	) * -1.0;

	y += get_linear_depth(
		uv + vec2(-offset.x, offset.y),
		INV_PROJECTION_MATRIX
	) * 1.0;

	y += get_linear_depth(
		uv + vec2(0.0, offset.y),
		INV_PROJECTION_MATRIX
	) * 2.0;

	y += get_linear_depth(
		uv + vec2(offset.x, offset.y),
		INV_PROJECTION_MATRIX
	) * 1.0;

	float depth_edge = sqrt(x * x + y * y);

	depth_edge /= max(depth_center, 0.001);

	// =====================
	// Detecção por Normais
	// =====================

	vec3 normal_center =
		texture(NORMAL_TEXTURE, uv).xyz;

	vec3 normal_left =
		texture(NORMAL_TEXTURE,
			uv + vec2(-offset.x, 0.0)).xyz;

	vec3 normal_right =
		texture(NORMAL_TEXTURE,
			uv + vec2(offset.x, 0.0)).xyz;

	vec3 normal_up =
		texture(NORMAL_TEXTURE,
			uv + vec2(0.0, offset.y)).xyz;

	vec3 normal_down =
		texture(NORMAL_TEXTURE,
			uv + vec2(0.0, -offset.y)).xyz;

	float normal_edge = 0.0;

	normal_edge += length(normal_center - normal_left);
	normal_edge += length(normal_center - normal_right);
	normal_edge += length(normal_center - normal_up);
	normal_edge += length(normal_center - normal_down);

	ALBEDO = outline_color.rgb;

	if (
		depth_edge > sensitivity ||
		normal_edge > normal_sensitivity
	) {
		ALPHA = outline_color.a;
	}
	else {
		ALPHA = 0.0;
	}
}