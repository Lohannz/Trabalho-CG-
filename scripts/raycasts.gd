extends Node3D
@onready var raycasts := $".".get_children()
@onready var camera = $/root/Principal/Camera3D
## variavel que o pai(player) ver para identificar o sentido do portal que vai ser pego
var SIDE : String 

func get_side() -> String:
	for child in raycasts:
		if child.is_colliding():
			var collider = child.get_collider()
			if collider in get_tree().get_nodes_in_group("Portals"):
				return child.name
	return ""
	
func _resetRaycasts(newOrientation):
	var directions = {
		"left": -newOrientation.x,
		"right": newOrientation.x,
		"up": newOrientation.y,
		"down": -newOrientation.y
	}
	
	for child in raycasts:
		if child.name in directions:
			child.set_target_position(directions[child.name] * 5)
	print("resetei")
	
#func _process(delta: float) -> void:
#	pass
	
func _ready() -> void:
	pass
	#camera.orientation_changed.connect(_resetRaycasts)
