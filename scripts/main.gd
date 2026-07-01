extends Node3D

@onready var player := $player

# REFERÊNCIAS DA SUA NOVA TELA DE CARREGAMENTO
@onready var loading_screen := $telaLoading
@onready var label_porcentagem := $telaLoading/FundoPreto/LabelPorcentagem
@onready var UI := $Camera3D/UI

@export_file("*.tscn") var level_path: String

var spawnpoints : Array[Vector3]
var current_level: Node3D
var carregando := false

func _ready() -> void:
	player.visible = false
	UI.visible = false
	if level_path != "":
		loading_screen.visible = true
		label_porcentagem.text = "0%"
		
		ResourceLoader.load_threaded_request(level_path)
		carregando = true

func _process(_delta: float) -> void:
	# verifica o carregamento
	if carregando:
		var progresso = []
		var status = ResourceLoader.load_threaded_get_status(level_path, progresso)
		
		# Pega o estado e coloca na labelPorcentagem
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Transforma o progresso (0.0 a 1.0) em número inteiro (0 a 100)
			var porcentagem = int(progresso[0] * 100)
			
			label_porcentagem.text = str(porcentagem) + "%"
			
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			carregando = false
			
			# Se tiver carregada, instancia ela e troca para ela
			var scene_resource = ResourceLoader.load_threaded_get(level_path)
			current_level = scene_resource.instantiate()
			$Fase.add_child(current_level)
			
			match current_level.name:
				"FASE 1":
					$Camera3D/Outline.material_override.set_shader_parameter("outline_color",Color(0.0, 0.008, 0.196))
					$WorldEnvironment.environment.fog_light_color = Color(0.264, 0.356, 1.007)
				"FASE 2":
					$"Camera3D/Pos-processamento/Nevasca".hide()
					$Camera3D/Outline.material_override.set_shader_parameter("outline_color",Color(0.168, 0.009, 0.048, 1.0))
					$WorldEnvironment.environment.fog_light_color = Color(0.482, 0.0, 0.173)
					
			configurar_spawn()
			
			loading_screen.visible = false
			player.visible = true
			UI.visible = true
						
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			carregando = false
			label_porcentagem.text = "Erro ao carregar fase!"

func configurar_spawn() -> void:
	var markers = current_level.get_node("Spawnpoints").get_children()
	for spawnpoint in markers:
		spawnpoints.append(spawnpoint.global_position)

	if spawnpoints.size() > 0:
		player.position = spawnpoints[0]
		player.spawnpoint = spawnpoints[0]
