extends Node3D
@export var speed: float  = 1.25
@export var directionVarianceSpeed: float = 0.13

var noise := FastNoiseLite.new()
var time = 0.0
var actualAxis: Vector3 = Vector3.UP

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * directionVarianceSpeed
	var x = noise.get_noise_1d(time)
	var y = noise.get_noise_1d(time + 100.0)
	var z = noise.get_noise_1d(time + 200.0)
	actualAxis = Vector3(x, y, z).normalized()
	rotate_object_local(actualAxis, speed * delta)
