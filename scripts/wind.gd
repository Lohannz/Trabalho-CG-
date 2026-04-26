extends Area3D
@export var WIND_DIRECTION : Vector3
# Nao sei se vai ser fixo para todos ou flexivel ainda :/
@export var WIND_POWER_V: float
@export var WIND_POWER_H: float

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.IN_WIND = true
		
		var dir = WIND_DIRECTION.normalized()
		var up = body._orientation.y
		
		var vertical = up * dir.dot(up)
		var horizontal = dir - vertical
		
		var wind_v = vertical * WIND_POWER_V
		var wind_h = horizontal * WIND_POWER_H
		
		body.WIND_FORCE = wind_v + wind_h

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.IN_WIND = false
		body.WIND_FORCE = Vector3.ZERO
