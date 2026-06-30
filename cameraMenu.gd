extends Camera3D

@export var velocidade := 0.95
@export var amplitude := 0.32

var tempo := 0.0
var posicao_inicial : Vector3

func _ready():
	posicao_inicial = position

func _process(delta):
	tempo += delta

	position.y = posicao_inicial.y + sin(tempo * velocidade) * amplitude
