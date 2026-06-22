extends Node3D
@onready var player := $player
@export var level_scene: PackedScene

var spawnpoints : Array[Vector3]
var current_level

# Ao iniciar cena, faz com que o player surja no MainSpawn da fase atual.
# Cada fase tem um node Spawnpoints contendo o MainSpawn e os outros pontos.
func _ready() -> void:
	if level_scene:
		current_level = level_scene.instantiate()
		$Fase.add_child(current_level)
		
		# Extrai os Spawnpoints como posições vetoriais e distribui em um Array.
		var markers = current_level.get_node("Spawnpoints").get_children()
		for spawnpoint in markers:
			spawnpoints.append(spawnpoint.global_position)

	# Cada índice é o Spawnpoint de uma face, o MainSpawn = 0.
	player.position = spawnpoints[0]
	player.spawnpoint = 0

func _get_spawnpoint_position(index : int) -> Vector3:
	return spawnpoints[index]

func _process(delta : float) -> void:
	pass
