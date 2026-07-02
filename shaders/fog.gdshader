shader_type fog;

uniform vec4 fog_color : source_color = vec4(0.02, 0.02, 0.05, 1.0); // Cor da escuridão da névoa
uniform sampler2D texture_noise : source_color, filter_nearest, repeat_enable;

uniform float base_density : hint_range(0.0, 100.0) = 20.0; // Densidade alta para bloquear o exterior
uniform float height_falloff : hint_range(0.1, 30.0) = 0.5;
uniform float texture_cutoff : hint_range(0.0, 1.0) = 0.4;

uniform vec3 fog_scale = vec3(0.1, 0.1, 0.1);
uniform vec3 fog_speed = vec3(0.03, 0.01, 0.02);

void fog() {
    vec3 w_pos = WORLD_POSITION;
    vec2 uv_xz = w_pos.xz * fog_scale.xz + (TIME * fog_speed.xz);
    float noise_xz = texture(texture_noise, uv_xz).r;
    
    vec2 uv_xy = w_pos.xy * fog_scale.xy + (TIME * fog_speed.xy);
    float noise_xy = texture(texture_noise, uv_xy).r;
    
    float noise_3d = min(noise_xz, noise_xy);
    float sharp_mix = step(texture_cutoff, noise_3d);
    float height_fade = pow(1.0 - UVW.y, height_falloff);
    

    DENSITY = base_density * sharp_mix * height_fade;
    ALBEDO = fog_color.rgb;
    EMISSION = vec3(0.0);
}