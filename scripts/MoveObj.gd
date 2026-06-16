extends MeshInstance3D

@export var center : Vector3 = Vector3.ZERO
@export var radius : float = 25.0
@export var speed : float = 1.0

var movebleNodes = []
var angle : float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:

	angle += speed * delta

	var index := 0
	var local_angle = angle + index

	global_position.x = center.x + cos(local_angle) * radius
	global_position.y = center.y + sin(local_angle) * radius

	index += TAU / max(movebleNodes.size(), 1)
