extends ColorRect

var death_shader = preload("res://shaders/death_transition.gdshader")
var start_shader = preload("res://shaders/start_transition.gdshader")

func set_shaders(transition : String):
	match transition:
		"start_level":
			material.shader = start_shader
			material.set_shader_parameter("cutoff", -0.5)
			material.set_shader_parameter("pixel_size", 10.0)
			material.set_shader_parameter("blur_amount", 0.05)
		"death":
			material.shader = death_shader
			material.set_shader_parameter("cutoff", 0.0)
			material.set_shader_parameter("pixel_size", 5.0)
	
