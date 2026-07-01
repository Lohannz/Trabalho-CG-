shader_type canvas_item;

uniform float cutoff : hint_range(0.0, 2.0) = 0.0;
uniform float pixel_size : hint_range(1, 100) = 5.0;
uniform float blur_amount : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 pos = UV;
    
    float pixel_offset = sin(pos.y * pixel_size) * 0.02;
    float pixelated_x = floor((-pos.x + pixel_offset + cutoff) * pixel_size) / pixel_size;

    // Trocamos o step por smoothstep para criar a transição suave (borrado)
    // O blur_amount define a largura dessa faixa de transição
    float is_covered = smoothstep(0.5 - blur_amount, 0.5 + blur_amount, pixelated_x);
	
    COLOR.a *= is_covered;
}