shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
// Importante: Adicionado hint_screen_texture
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Corrigido: hint_default_transparent impede que a textura se repita infinitamente nas bordas
uniform sampler2D flake_texture : hint_default_transparent, filter_linear_mipmap;

uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float density : hint_range(1.0, 1000.0) = 20.0; // Ajustado padrão para criar uma grade visível
uniform float size : hint_range(0.01, 1.0) = 0.2;     // Ajustado padrão para o tamanho do floco na célula

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
            
            // Posição aleatória do floco dentro da célula vizinha
            vec2 pos = vec2(seed, seed2);
            pos.x += tempo * wind; // negativo = esquerda
			pos.y += tempo;         // positivo = baixo
			pos.x = fract(pos.x);  // faz reaparecer do outro lado
			pos.y = fract(pos.y);
            
            // Vetor de distância entre o pixel atual e o floco vizinho
            vec2 diff = vec2(float(x), float(y)) + pos - local;
			
            // Centraliza e redimensiona a UV do floco dentro do espaço da célula
            vec2 flake_uv = (diff / size) * 0.5 + 0.5;
            
            flake_uv.y = 1.0 - flake_uv.y;
            
            // Só desenha se a UV gerada estiver estritamente dentro do quadrado da textura (0 a 1)
           if(flake_uv.x >= 0.0 && flake_uv.x <= 1.0 && 
		   flake_uv.y >= 0.0 && flake_uv.y <= 1.0) {
		    vec4 s = texture(tex, flake_uv);
		    
		    // remove pixels próximos do branco
		    float brightness = dot(s.rgb, vec3(0.333));
		    s.a *= 1.0 - smoothstep(0.7, 1.0, brightness);
		    
		    resultado = mix(resultado, s, s.a);
		}
        }
    }
    return clamp(resultado, 0.0, 1.0);
}
uniform int pixel_size : hint_range(1, 32) = 3;

void fragment() {
	
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    float x = float(int(SCREEN_UV.x * screen_size.x) % pixel_size);
    float y = float(int(SCREEN_UV.y * screen_size.y) % pixel_size);
    x = (SCREEN_UV.x * screen_size.x) + floor(float(pixel_size) / 2.0) - x;
    y = (SCREEN_UV.y * screen_size.y) + floor(float(pixel_size) / 2.0) - y;
    COLOR = texture(SCREEN_TEXTURE, vec2(x, y) * SCREEN_PIXEL_SIZE);
	COLOR += vec4(0.02, 0, 0.1, 0.2); // cor roxa
	
    float t = TIME * speed;
    vec4 neve = floco(SCREEN_UV, t, density, flake_texture);
    vec4 tela = texture(SCREEN_TEXTURE, SCREEN_UV);
    COLOR += mix(tela, neve, neve.a);
}
