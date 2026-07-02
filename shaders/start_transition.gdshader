shader_type canvas_item;

uniform float cutoff : hint_range(-0.5, 1.5) = -0.5;
uniform float pixel_size : hint_range(1.0, 500.0) = 20.0;
uniform float blur_amount : hint_range(0.001, 0.5) = 0.25;

void fragment() {
    vec2 uv = UV;
    float ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    uv.x = (uv.x - 0.5) / ratio + 0.5;
    
    vec2 center = vec2(0.5 / ratio, 0.5);
    float dist = distance(uv, vec2(0.5, 0.5));
    
    float pixel_offset = sin(uv.y * pixel_size + TIME * 5.0) * 0.02;
    float pixelated_dist = floor((dist + pixel_offset + cutoff) * pixel_size) / pixel_size;
    
    float is_covered = smoothstep(0.5 - blur_amount, 0.5 + blur_amount, pixelated_dist);
 
    COLOR.a = is_covered;
}