extends ColorRect
@onready var camera: Camera3D = get_tree().current_scene.get_node("Camera3D")

func _process(_delta: float) -> void:
	pass
	
	if camera:
		#var gravity: Vector3 = -camera.global_transform.basis.y
		var direction : Vector2 = Vector2(-0.5,-1)
		
		material.set_shader_parameter("direction", direction)
