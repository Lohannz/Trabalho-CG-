extends Area3D
@export var WIND_DIRECTION : Vector3
@export var WIND_POWER: float

func _ready():
	# Calcula a rotação do vento baseado na força.
	$WindMesh.set_instance_shader_parameter("rotation_speed", (WIND_POWER/100.0) * 0.15)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.ext_effects.append(Globals.EFFECTS.WIND)
		
		var dir = WIND_DIRECTION.normalized()
		var up = body._orientation.y
		
		var vertical = up * dir.dot(up)
		var horizontal = dir - vertical
		
		var wind_v = vertical * WIND_POWER
		var wind_h = horizontal * WIND_POWER
		
		body.WIND_FORCE = wind_v + wind_h

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.ext_effects.erase(Globals.EFFECTS.WIND)
		body.WIND_FORCE = Vector3.ZERO
