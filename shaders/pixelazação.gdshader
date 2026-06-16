shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int pixel_size : hint_range(1, 32) = 8;

void fragment() {
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;

    float x = float(int(SCREEN_UV.x * screen_size.x) % pixel_size);
    float y = float(int(SCREEN_UV.y * screen_size.y) % pixel_size);

    x = (SCREEN_UV.x * screen_size.x) + floor(float(pixel_size) / 2.0) - x;
    y = (SCREEN_UV.y * screen_size.y) + floor(float(pixel_size) / 2.0) - y;

    COLOR = texture(SCREEN_TEXTURE, vec2(x, y) * SCREEN_PIXEL_SIZE);

    // opcional
    COLOR += vec4(0.02, 0.0, 0.1, 0.2);
}