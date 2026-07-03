extends MeshInstance3D

@export var distancia: float = 30.0
@export var direcao: Vector3 = Vector3.RIGHT
@export var velocidade: float = 5.0
var zona_suavizacao: float = 8.0       
var fator_velocidade_minima: float = 0.4  # velocidade mínima nas pontas (0 = para totalmente, 1 = sem suavização)

var _origem: Vector3
var _progresso: float = 0.0
var _sentido: float = 1.0
var _body: StaticBody3D

func _ready() -> void:
	_origem = global_position
	_body = get_node("StaticBody3D")

func _physics_process(delta: float) -> void:
	var fator := _calcular_fator_velocidade()
	var velocidade_atual := velocidade * fator

	_progresso += _sentido * velocidade_atual * delta
	if _progresso >= distancia:
		_progresso = distancia
		_sentido = -1.0
	elif _progresso <= 0.0:
		_progresso = 0.0
		_sentido = 1.0

	global_position = _origem + direcao.normalized() * _progresso
	_body.constant_linear_velocity = direcao.normalized() * velocidade_atual * _sentido

func _calcular_fator_velocidade() -> float:
	if zona_suavizacao <= 0.0:
		return 1.0
	var dist_borda = min(_progresso, distancia - _progresso)
	if dist_borda >= zona_suavizacao:
		return 1.0
	var t = dist_borda / zona_suavizacao
	var suave = t * t * (3.0 - 2.0 * t)  # smoothstep, curva de ease in/out
	return lerp(fator_velocidade_minima, 1.0, suave)
