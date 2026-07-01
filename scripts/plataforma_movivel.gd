extends MeshInstance3D

@export var distancia: float = 30.0
@export var direcao: Vector3 = Vector3.RIGHT
@export var velocidade: float = 5.0

var _origem: Vector3
var _progresso: float = 0.0
var _sentido: float = 1.0
var _body: StaticBody3D

func _ready() -> void:
	_origem = global_position
	_body = get_node("StaticBody3D")

func _physics_process(delta: float) -> void:
	_progresso += _sentido * velocidade * delta

	if _progresso >= distancia:
		_progresso = distancia
		_sentido = -1.0
	elif _progresso <= 0.0:
		_progresso = 0.0
		_sentido = 1.0
		
	global_position = _origem + direcao.normalized() * _progresso
	_body.constant_linear_velocity = direcao.normalized() * velocidade * _sentido
