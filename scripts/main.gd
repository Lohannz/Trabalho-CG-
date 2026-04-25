extends Node3D
@export var Face := 1
@onready var player := $player
@onready var spawnpoints := $Spawnpoints.get_children()

enum FACE {ONE, TWO, THREE, FOUR, FIVE, SIX}

# Ao iniciar cena, faz com que o player spawne no spawnpoint da current_face que ele está 
# Player tem propriedade current_face que diz qual lado do cubo ele está
func _ready() -> void:
	# os spawnpoints tem os nomes da face(ex. ONE, TWO...)
	var player_current_face = FACE.keys()[player.current_face] 
	var current_spawn_position = _get_spawnpoint_position(player_current_face)
	
	player.position = current_spawn_position

func _get_spawnpoint_position(name) -> Vector3:
	for child in spawnpoints:
		print(child.name)
		print(name)
		if child.name == str(name):
			return child.global_position
	return Vector3.ZERO
	
func _process(delta: float) -> void:
	pass
