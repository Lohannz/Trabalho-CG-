extends Node3D

@export var destination : Area3D
@export var numFace :int

signal player_entered(destination_pos : Vector3, face : int)
signal player_nearby(is_near : bool)

var player_inside := false

func _on_body_entered(body : Node3D) -> void:
	if body is CharacterBody3D:
		player_inside = true	
		player_nearby.emit(true)
		
func _on_body_exited(body : Node3D):
	if body is CharacterBody3D:
		player_inside = false
		player_nearby.emit(false)

func _process(delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("ui_U"):
		player_entered.emit(destination.global_position, numFace)
		
func _ready() -> void:
	add_to_group("Portals")
