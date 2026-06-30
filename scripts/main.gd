extends Node3D

@onready var player := $player
@onready var fase_container := $Fase

var spawnpoints : Array[Vector3]
var current_level: Node3D

func _ready() -> void:
	load_level()

func load_level() -> void:
	# Verifica se há um caminho de fase válido no SGameManager
	if GameManager.next_level_path != "":
		# Carrega a fase escolhida na memória
		var level_resource = load(GameManager.next_level_path)
		
		# Instancia a fase
		current_level = level_resource.instantiate()
		fase_container.add_child(current_level)

		# Configura os spawnpoints do jogador
		setup_player_spawn()

func setup_player_spawn() -> void:
	# Sempre bom verificar se os nós existem para evitar crashes
	if current_level.has_node("Spawnpoints"):
		var markers = current_level.get_node("Spawnpoints").get_children()
		for spawnpoint in markers:
			spawnpoints.append(spawnpoint.global_position)
			
		if spawnpoints.size() > 0:
			player.global_position = spawnpoints[0]
			# Assumindo que seu player tem essa variável
			player.spawnpoint = spawnpoints[0]
