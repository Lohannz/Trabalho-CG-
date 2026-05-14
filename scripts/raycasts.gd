extends Node3D
@onready var raycasts := $".".get_children()
@onready var camera = $/root/Principal/player/Camera3D
## variavel que o pai(player) ver para identificar o sentido do portal que vai ser pego
var SIDE : String 

func get_side() -> String:
	for child in raycasts:
		if child.is_colliding():
			var collider = child.get_collider()
			if collider in get_tree().get_nodes_in_group("Portals"):
				return child.name
	return ""
	
func _resetRaycasts(newX, newY):
	print("X: ", newX)
	print("Y: ", newY)
	for child in raycasts:
		if child.name == "left":
			child.set_target_position(-newX * 5)
		if child.name == "right":
			child.set_target_position(newX * 5)
		if child.name == "up":
			child.set_target_position(newY * 5)
		if child.name == "down":
			child.set_target_position(-newY * 5)
		

	print("resetei")
	
func _process(delta: float) -> void:
	pass
	
func _ready() -> void:
	camera.up_changed.connect(_resetRaycasts)
	camera.horizontal_changed.connect(_resetRaycasts)
