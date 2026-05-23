shader_type spatial;


uniform vec3 emission_color : source_color = vec3(0, 0.9, 0.9);
uniform float emission_energy : hint_range(0.0, 10.0) = 10.0;
void fragment() {
    ALBEDO = vec3(0, 0.4, 0.7);
    
    EMISSION = emission_color * emission_energy;
}