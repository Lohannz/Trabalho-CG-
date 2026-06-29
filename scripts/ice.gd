extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.ext_effects.append(Globals.EFFECTS.ICE)
		
func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.ext_effects.erase(Globals.EFFECTS.ICE)
