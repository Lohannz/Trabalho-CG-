extends ColorRect

@onready var camera: Camera3D = get_tree().current_scene.get_node("Camera3D")

func _process(_delta: float) -> void:
	if !camera or !(material is ShaderMaterial):
		return
	var gravity_world: Vector3 = -camera.game_basis.y
	var gravity_view: Vector3 = camera.global_transform.basis.inverse() * gravity_world

	var direction := Vector2(gravity_view.x, -gravity_view.y).normalized()
	(material as ShaderMaterial).set_shader_parameter("direction", direction)
