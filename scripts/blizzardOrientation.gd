extends ColorRect
@onready var camera: Camera3D = get_tree().current_scene.get_node("Camera3D")

func _process(_delta: float) -> void:
	pass
	"""
	if camera:
		var gravity: Vector3 = -camera.global_transform.basis.y
		var direction : Vector2
		if gravity.is_equal_approx(Vector3(0,1,0)): 
			direction = -Vector2(0,1)
		elif gravity.is_equal_approx(Vector3(0,0,1)): 
			direction = -Vector2(0,1)
		elif gravity.is_equal_approx(Vector3(0,0,-1)): 	
			direction = -Vector2(0,1)
		material.set_shader_parameter("direction", direction)
"""
