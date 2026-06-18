shader_type spatial;

uniform vec3 emission_color : source_color = vec3(0.0, 0.54, 0.7);


void fragment() {
	float emission_energy = sin(TIME * 2.0) + 1.1;
    ALBEDO = emission_color;
    
    EMISSION = emission_color * emission_energy * 10.0;
	
}