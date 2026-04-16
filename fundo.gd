extends MeshInstance3D

func _ready() -> void:
	pass 


var meshes := []
var pos_x_reset = -100
var speed = 0.1
var limit_x = 5000

func _process(delta: float) -> void:
	
	translate(Vector3((speed * delta), 0, 0))
	
	scale = global_basis.get_scale()
	if global_transform.origin.x >= limit_x:
		var pos = global_transform.origin
		pos.x = pos_x_reset
		global_transform.origin = pos
		
		
	
			
