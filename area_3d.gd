extends Area3D
@export var WIND_DIRECTION : Vector3
var WIND_POWER: float = 50

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.IN_WIND = true
		body.WIND_FORCE = WIND_POWER * WIND_DIRECTION.normalized()


func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.IN_WIND = false
		body.WIND_FORCE = Vector3.ZERO
