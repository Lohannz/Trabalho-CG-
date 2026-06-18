shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Configurações da Nevasca
uniform float wind = 0.5;
uniform float fog_density = 0.4;
uniform vec4 fog_color : source_color = vec4(0.58, 0.82, 0.95, 1.0);
uniform float blur = 0.02;

void fragment() {
	vec2 uv_translation = SCREEN_UV + vec2(TIME * wind * 0.08, TIME * (wind * -0.7));

	float noise = texture(noise_texture, uv_translation).r;
	
	vec2 uv_distorcion = SCREEN_UV + vec2(noise - 0.5) * blur;
	
	vec3 screen_image = texture(SCREEN_TEXTURE, uv_distorcion).rgb;
	
	//float weather_mask = smoothstep(0.2, 0.8, noise) * fog_density;
	
	float snow_cells = 0.25;
	float sharpness = 0.70;    
	float weather_mask = smoothstep(snow_cells, sharpness, noise) * fog_density;
	
	float vignette = distance(SCREEN_UV, vec2(0.5));
	weather_mask += smoothstep(0.3, 1.0, vignette) * (fog_density * 0.5);
	
	weather_mask = clamp(weather_mask, 0.0, 1.0);
	
	vec3 color_correction = mix(screen_image, fog_color.rgb, weather_mask);
	
	COLOR = vec4(color_correction, 1.0);
}