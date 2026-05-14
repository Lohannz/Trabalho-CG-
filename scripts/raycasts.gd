extends Node3D
@onready var raycasts := $".".get_children()

## variavel que o pai(player) ver para identificar o sentido do portal que vai ser pego
var SIDE : String 

func get_side() -> String:
	for child in raycasts:
		if child.is_colliding():
			var collider = child.get_collider()
			if collider in get_tree().get_nodes_in_group("Portals"):
				return child.name
	return ""
	
func _process(delta: float) -> void:
	pass
