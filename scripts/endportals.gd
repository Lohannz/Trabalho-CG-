extends Area3D
@export_file("*.tscn") var next_level_path: String

@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = true
		set_process_unhandled_input(true)

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = false
		set_process_unhandled_input(false)

func _unhandled_input(event):
	if not player.FREEZE and event.is_action_pressed("ui_F"):
		player.use_portal(self)
		
func _ready() -> void:
	set_process_unhandled_input(false)
	add_to_group("Portals")
