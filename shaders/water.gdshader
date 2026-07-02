shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo : source_color = vec4(0.0, 0.2, 0.4, 1.0); // Cor mais profunda da água
uniform vec4 shallow_color : source_color = vec4(0.1, 0.7, 0.8, 1.0); // Cor rasa/crista
uniform vec4 caustic_color : source_color = vec4(0.9, 0.95, 1.0, 1.0); // Cor da linha de luz do caustic

uniform sampler2D texture_caustics : source_color, filter_nearest, repeat_enable;

uniform float wave_height : hint_range(0.0, 2.0) = 0.15;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float wave_speed : hint_range(0.1, 10.0) = 2.5;

uniform vec2 caustics_scale = vec2(0.3, 0.3);
uniform float caustics_speed : hint_range(0.1, 5.0) = 0.8;
uniform float caustics_cutoff : hint_range(0.0, 1.0) = 0.45; 

varying vec3 world_pos;
varying float wave_intensity;

void vertex(){
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    wave_intensity = sin(world_vertex.z * wave_frequency + TIME * wave_speed) * cos(world_vertex.x * wave_frequency * 0.8 + TIME * wave_speed * 0.5);
    VERTEX.y += wave_intensity * wave_height;
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
    vec2 water_uv = world_pos.xz * caustics_scale;
  
    vec2 uv_motion1 = water_uv + vec2(TIME * caustics_speed * 0.025, TIME * caustics_speed * 0.015) + (wave_intensity * 0.02);
    vec2 uv_motion2 = (water_uv * 1.15) + vec2(TIME * caustics_speed * -0.035, TIME * caustics_speed * 0.02) - (wave_intensity * 0.015);
    
    vec4 caustic1 = texture(texture_caustics, uv_motion1);
    vec4 caustic2 = texture(texture_caustics, uv_motion2);
	
    float raw_caustic = min(caustic1.r, caustic2.r);
    float sharp_caustic = step(caustics_cutoff, raw_caustic);
    

    float wave_norm = (wave_intensity + 1.0) * 0.5;
    float gradient_factor = pow(wave_norm, 1.8);
    vec3 base_water_gradient = mix(albedo.rgb, shallow_color.rgb, gradient_factor);
    vec3 final_color = mix(base_water_gradient, caustic_color.rgb, sharp_caustic * 0.45);
    
    ALBEDO = final_color;
    ALPHA = albedo.a;
}