extends Node3D
@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")
var cond = false
func descongela():
	print("entos")
	var pilar= get_tree().get_nodes_in_group("pilar")[0]
	pilar.get_node("CollisionShape3D").disabled = false
	pilar.get_parent().hide()
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = true
		cond = true

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = false

func _process(_delta: float) -> void:
	if cond:
		if Input.is_action_just_pressed("ui_F"):
				descongela()
