shader_type canvas_item;

uniform sampler2D flake_texture : hint_default_transparent, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float speed : hint_range(0.1, 20.0) = 1.0;
uniform float density : hint_range(1.0, 1000.0) = 20.0;
uniform float size : hint_range(0.01, 1.0) = 0.2;
uniform float wind : hint_range(-1.0, 1.0) = -0.3;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec4 floco(vec2 uv, float tempo, float escala, sampler2D tex) {
    vec2 grade = uv * escala;
    vec2 celula = floor(grade);
    vec2 local = fract(grade);

    vec4 resultado = vec4(0.0);

    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {

            vec2 vizinha = celula + vec2(float(x), float(y));

            float seed = hash(vizinha);
            float seed2 = hash(vizinha + vec2(3.7, 1.5));

            vec2 pos = vec2(seed, seed2);

            pos.x += tempo * wind;
            pos.y += tempo;

            pos.x = fract(pos.x);
            pos.y = fract(pos.y);

            vec2 diff = vec2(float(x), float(y)) + pos - local;

            vec2 flake_uv = (diff / size) * 0.5 + 0.5;
            flake_uv.y = 1.0 - flake_uv.y;

            if(
                flake_uv.x >= 0.0 && flake_uv.x <= 1.0 &&
                flake_uv.y >= 0.0 && flake_uv.y <= 1.0
            ) {
                vec4 s = texture(tex, flake_uv);

                float brightness = dot(s.rgb, vec3(0.333));
                s.a *= 1.0 - smoothstep(0.7, 1.0, brightness);

                resultado = mix(resultado, s, s.a);
            }
        }
    }

    return clamp(resultado, 0.0, 1.0);
}

void fragment() {
    float t = TIME * speed;

    vec4 neve = floco(UV, t, density, flake_texture);

    // imagem original da tela
    vec4 tela = texture(SCREEN_TEXTURE, SCREEN_UV);

    // dessaturação leve
    float luminancia = dot(tela.rgb, vec3(0.299, 0.587, 0.114));
    vec3 cinza = vec3(luminancia);

    tela.rgb = mix(tela.rgb, cinza, 0.35);

    // tom frio azulado
    tela.rgb *= vec3(0.85, 0.9, 1.0);

    // névoa clara
    tela.rgb = mix(tela.rgb, vec3(0.75, 0.75, 0.8), 0.3);

    // adiciona a neve por cima
    COLOR = mix(tela, neve, neve.a);
}