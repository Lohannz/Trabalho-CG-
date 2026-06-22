shader_type spatial;
render_mode blend_mix, specular_schlick_ggx, unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// --- Uniforms ---
// Fresnel
uniform float fres_intensity = 2.5;
uniform vec4 fres_color : source_color;
uniform vec4 base_color : source_color;

// Texturas e Triplanar
uniform vec3 uv_tiling = vec3(1.0, 1.0, 1.0);
uniform vec3 uv_offset = vec3(0.0, 0.0, 0.0);
uniform sampler2D noise_tex : source_color;
uniform sampler2D normal_tex : hint_normal; // Sua textura de normal aqui

// Refração e Relevo
uniform float refraction = 1.0;
uniform float normal_depth = 0.77;

// Função de mapeamento triplanar limpa
vec4 get_triplanar_map(sampler2D tex, vec3 global_position, vec3 global_normal, vec3 tiling, vec3 offset){
	vec3 uv_position = global_position * tiling + offset;
	
	vec4 tex_x = texture(tex, uv_position.zy);
	vec4 tex_y = texture(tex, uv_position.xz);
	vec4 tex_z = texture(tex, uv_position.xy);
	
	vec3 blend = abs(global_normal);
	blend /= (blend.x + blend.y + blend.z);
	
	return tex_x * blend.x + tex_y * blend.y + tex_z * blend.z;
}

void fragment() {
	// Referência global para mapeamento da textura
	vec3 global_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 global_normal = abs(INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	
	// Efeito de fresnel ou iluminação lateral
	float fresnel_factor = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fres_intensity);
	vec3 composed_fres = vec3(fresnel_factor) * fres_color.rgb;

	// Amostragem da textura base (Albedo) via Triplanar
	vec4 ice_tex = get_triplanar_map(noise_tex, global_position, global_normal, uv_tiling, uv_offset);
	vec3 ice_color = ice_tex.rgb;

	// --- SUA REFRAÇÃO ORIGINAL (RESTAURADA) ---
	vec3 screen_coord = vec3(SCREEN_UV, 0.0);
	float brightness = dot(screen_coord, vec3(0.333333, 0.333333, 0.333333));
	
	float distortion_offset = brightness * ice_color.x;
	float distortion = brightness + distortion_offset;
	
	vec3 refracted_uv = (screen_coord - vec3(distortion)) * vec3(refraction) + screen_coord;
	vec4 screen_tex = texture(SCREEN_TEXTURE, refracted_uv.xy);
	vec3 screen_color = screen_tex.rgb;
	// ------------------------------------------

	// Composição de cores
	vec3 composed_screen = ice_color + screen_color;
	vec3 composed_albedo = composed_fres + (base_color.rgb * composed_screen);

	// Amostragem e aplicação da Textura de Normal via Triplanar
	vec4 normal_map_read = get_triplanar_map(normal_tex, global_position, global_normal, uv_tiling, uv_offset);

	// Atribuição dos outputs finais
	ALBEDO = composed_albedo;
	ALPHA = base_color.a;
	
	// Passando a textura de normal triplanar para o Godot processar o relevo
	NORMAL_MAP = normal_map_read.rgb;
	NORMAL_MAP_DEPTH = normal_depth;
}