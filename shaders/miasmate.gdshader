shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// Parâmetros que você pode alterar no Inspector
uniform vec4 cor_maligna : source_color = vec4(0.2, 0.0, 0.3, 1.0);
uniform vec4 cor_brilho : source_color = vec4(0.5, 0.0, 0.8, 1.0);
uniform float velocidade_translacao : hint_range(0.0, 2.0) = 0.2;
uniform vec3 direcao_vento = vec3(0.2, 1.0, 0.1); // Direção para onde a fumaça vai
uniform float escala_volume : hint_range(0.1, 10.0) = 2.0;
uniform float densidade_fumaca : hint_range(0.0, 5.0) = 1.2;

// Função matemática simples para gerar ruído pseudo-3D procedural (Saves de performance)
float hash(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.xyz, p.yzx + 19.19);
	return fract(p.x * p.y * p.z);
}

float noise3D(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	return mix(
		mix(mix(hash(i + vec3(0.,0.,0.)), hash(i + vec3(1.,0.,0.)), f.x),
			mix(hash(i + vec3(0.,1.,0.)), hash(i + vec3(1.,1.,0.)), f.x), f.y),
		mix(mix(hash(i + vec3(0.,0.,1.)), hash(i + vec3(1.,0.,1.)), f.x),
			mix(hash(i + vec3(0.,1.,1.)), hash(i + vec3(1.,1.,1.)), f.x), f.y), f.z);
}

void fragment() {
	// 1. Pegamos a posição real do pixel no mundo 3D (para ignorar as faces de UV da Mesh)
	// vertex_world_position é passada internamente pelo motor da Godot 4
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// 2. Cria o vetor de translação uniforme com base no tempo e na direção do vento
	vec3 offset_tempo = normalize(direcao_vento) * TIME * velocidade_translacao;
	
	// 3. Modifica as coordenadas espaciais para aplicar o zoom e o movimento lento
	vec3 coordenadas_finais = (world_pos * escala_volume) - offset_tempo;
	
	// 4. Calcula duas camadas de ruído em escalas diferentes para dar aspecto gasoso/espesso
	float camada_base = noise3D(coordenadas_finais);
	float camada_detalhe = noise3D(coordenadas_finais * 2.0 + vec3(5.0)) * 0.5;
	
	// Combina as duas texturas procedurais
	float intensidade_fumaca = (camada_base + camada_detalhe) * densidade_fumaca;
	intensidade_fumaca = clamp(intensidade_fumaca, 0.0, 1.0);
	
	// 5. Aplicação Visual
	// Mistura a cor escura de base com o brilho neon maligno nas áreas mais densas
	vec3 cor_final = mix(cor_maligna.rgb, cor_brilho.rgb, intensidade_fumaca);
	
	ALBEDO = cor_final;
	
	// Controla a transparência baseada no ruído volumétrico para parecer fumaça cortando o cubo
	ALPHA = intensidade_fumaca * cor_maligna.a;
}