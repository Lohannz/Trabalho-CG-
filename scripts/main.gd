extends Node3D

@onready var player := $player

# REFERÊNCIAS DA TELA DE CARREGAMENTO	
@onready var loading_screen := $telaLoading
@onready var label_percent := $telaLoading/FundoPreto/LabelPorcentagem
@onready var UI := $Camera3D/UI

@onready var transition_layer = $"Camera3D/Pos-processamento/Transição/transição"
@onready var transition = $"Camera3D/Pos-processamento/Transição/transição/AnimationPlayer"

@export_file("*.tscn") var level_path: String
var spawnpoints : Array[Vector3]
var current_level: Node3D
var loading := false

signal level_ready

func _ready() -> void:
	player.change_level.connect(start_loading)
	start_loading(level_path)

func start_loading(new_path: String) -> void:
	if loading: return
	
	level_path = new_path
	loading = true
	
	# Preparação da UI de carregamento.
	player.visible = false
	player.FREEZE = true
	player.input.DISABLED = true
	UI.visible = false
	loading_screen.visible = true
	label_percent.text = "0%"
	
	# Descarregamento da fase anterior.
	if is_instance_valid(current_level):
		current_level.queue_free() 
		current_level = null
		spawnpoints.clear() # Limpa os spawns da fase anterior
	
	# Carregamento em background
	ResourceLoader.load_threaded_request(level_path)

func _process(_delta: float) -> void:
	if loading:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(level_path, progress)
		
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var percent = int(progress[0] * 100)
			label_percent.text = str(percent) + "%"
			
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			loading = false
			# Para a musica do menu
			MusicaGlobal.musicaMenu.stop()

			var scene_resource = ResourceLoader.load_threaded_get(level_path)
			current_level = scene_resource.instantiate()
			$Fase.add_child(current_level)

			# Configurações estéticas baseadas nas fases.
			transition_layer.set_shaders("start_level")
			match current_level.name:
				"FASE 1":
					MusicaGlobal.play("fase1")
					$"Camera3D/Pos-processamento/Nevasca".show()
					$Camera3D/Outline.material_override.set_shader_parameter("outline_color", Color(0.0, 0.008, 0.196))
					
					transition_layer.color = Color(0.1, 0.0, 0.618)
					$WorldEnvironment.environment.fog_light_color = Color(0.264, 0.356, 1.007)
					$WorldEnvironment/DirectionalLight3D.show()
					
					$"player/cat_obj/armature_cat/Skeleton3D/BoneAttachment3D/lamparina".hide()
					$player/AreaLamp/LampCol.disabled = true
					
				"FASE 2":
					MusicaGlobal.play("fase2")
					$"Camera3D/Pos-processamento/Nevasca".hide()
					$Camera3D/Outline.material_override.set_shader_parameter("outline_color", Color(0.168, 0.009, 0.048, 1.0))
					
					transition_layer.color = Color(0.129, 0.008, 0.09)
					$WorldEnvironment.environment.background_color = Color(0.482, 0.0, 0.172, 1.0)
					$WorldEnvironment.environment.fog_light_color = Color(0.482, 0.0, 0.172, 1.0)
					$WorldEnvironment/DirectionalLight3D.hide()
					
					$"player/cat_obj/armature_cat/Skeleton3D/BoneAttachment3D/lamparina".show()
					$player/AreaLamp/LampCol.disabled = false
					
				"FASE 3A":
					#MusicaGlobal.play("fase2")
					$"Camera3D/Pos-processamento/Nevasca".hide()
					$Camera3D/Outline.material_override.set_shader_parameter("outline_color", Color(0.169, 0.0, 0.631, 1.0))
					
					transition_layer.color = Color(0.059, 0.0, 0.294, 1.0)
					$WorldEnvironment.environment.background_color = Color(0.396, 0.002, 0.855, 1.0)
					$WorldEnvironment.environment.fog_light_color = Color(0.291, 0.12, 0.721, 1.0)
					$WorldEnvironment/DirectionalLight3D.hide()
					
					$"player/cat_obj/armature_cat/Skeleton3D/BoneAttachment3D/lamparina".hide()
					$player/AreaLamp/LampCol.disabled = true

					
			spawn_setting()
			level_ready.emit()
			
			# Reativação do jogo.
			player.FREEZE = false
			
			await $Camera3D.wait_camera_arrives()
			loading_screen.visible = false
			player.visible = true
			
			transition.play_backwards(&"start_level")
			await transition.animation_finished
			transition_layer.set_shaders("death")
			
			player.input.DISABLED = false
			UI.visible = true
						
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			loading = false
			label_percent.text = "Erro ao carregar fase!"

func spawn_setting() -> void:
	# Evita carregamento caso não hajam Spawnpoints.
	if not current_level.has_node("Spawnpoints"):
		push_error("Nenhum Spawnpoint na fase!")
		return
		
	var markers = current_level.get_node("Spawnpoints").get_children()
	for spawnpoint in markers:
		spawnpoints.append(spawnpoint.global_position)

	if spawnpoints.size() > 0:
		player.global_position = spawnpoints[0]
		player.spawnpoint = spawnpoints[0]
