extends Area3D
@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")
@onready var barrier : StaticBody3D = get_tree().get_nodes_in_group("barrier")[0]
const CRYSTAL = preload("res://models/import/materials/crystal_spikes.tres")

func _melt_barrier():
	barrier.get_node("CollisionShape3D").disabled = true
	barrier.get_parent().hide()
	
	self.get_node("CollisionShape3D").disabled = true
	self.get_node("crystal_core").hide()
	_melt_scenario()

func _melt_scenario():
	var nodes = get_tree().get_nodes_in_group("meltable")
	
	for node in nodes:
		if node is MeshInstance3D:
			if not node.is_in_group("killObj"):
				node.get_node("StaticBody3D").set_collision_layer_value(3, true)	
			node.material_override = CRYSTAL
		elif node is Area3D:
			node.get_node("CollisionShape3D").disabled = false 
			node.show()

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player.PORTAL_UI.visible = false

func _process(_delta: float) -> void:
	if player in self.get_overlapping_bodies():
		if Input.is_action_just_pressed("ui_F"):
				_melt_barrier()
