shader_type spatial;

render_mode blend_mix, depth_draw_opaque;

uniform sampler2D noise;

uniform float speed = 0.05;
uniform float wave = 0.03;

uniform vec3 shallow_color : source_color = vec3(0.42, 0.73, 0.95);
uniform vec3 deep_color : source_color = vec3(0.18, 0.42, 0.80);
uniform vec3 highlight_color : source_color = vec3(0.75, 0.90, 1.0);

uniform float alpha = 0.45;

void vertex() {

    VERTEX.y += sin(UV.x * 15.0 + TIME * 3.0) * wave;
    VERTEX.y += cos(UV.y * 12.0 + TIME * 2.0) * wave;
}

void fragment() {

    vec2 uv = UV;

    uv += vec2(TIME * speed, TIME * speed * 0.3);

    float n = texture(noise, uv).r;

    // Segunda camada de ruído
    float n2 = texture(noise, uv * 2.3 + vec2(3.1, 1.8)).r;

    // Mistura entre azul claro e escuro
    vec3 color = mix(deep_color, shallow_color, n);

    // Pequenos brilhos
    color = mix(color, highlight_color, smoothstep(0.75, 1.0, n2) * 0.35);

    ALBEDO = color;


    ROUGHNESS = 0.08;

    SPECULAR = 0.6;
}