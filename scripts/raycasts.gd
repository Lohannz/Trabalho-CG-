extends Node3D

@onready var raycasts := $".".get_children()

## variavel que o pai(player) ver para identificar o sentido do portal que vai ser pego
var which_portal : String 
func _process(delta: float) -> void:
	for child in raycasts:
		if child.is_colliding():
			var collider = child.get_collider()
			if collider in get_tree().get_nodes_in_group("Portals"):
				# se o raycast tá encostando em um portal
				# manda para o player dizendo qual é o lado do portal( esquerda, cima etc)
				if child.name == "right":
					which_portal =	"right"
				elif child.name == "left":
					which_portal = "left"
				elif collider.name == "up":
					which_portal = "up"
				else:
					which_portal = "down"
				
				
