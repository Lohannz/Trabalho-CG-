extends Node3D
@export var destination : Area3D
@export var spawnpoints : Array[Marker3D]

@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = true
		set_process_unhandled_input(true)

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = false
		set_process_unhandled_input(false)
	
func get_normal() -> Vector3:
	var normal = -global_basis.z.normalized()
	return normal

func get_spawn() -> Vector3:
	for spawn in spawnpoints:
		if spawn.transform.basis.y.is_equal_approx(player.up):
			return spawn.global_position
	return spawnpoints[0].global_position

func _unhandled_input(event):
	if not player.FREEZE and event.is_action_pressed("ui_F"):
		player.use_portal(self)
		
func _ready() -> void:
	set_process_unhandled_input(false)
	add_to_group("Portals")
