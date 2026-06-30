extends Node3D

@export var speed := 40.0

func _process(delta):
	rotate_y(deg_to_rad(speed * delta))
"res://scenes/Fase 1 - cavernas de gelo/fase_1.tscn"
