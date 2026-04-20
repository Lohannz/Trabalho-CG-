extends Camera3D

@export var distancia := 25.0
@export var lerp_speed := 3.0

# de qual lado a câmera fica em cada face
var faces := [
	Vector3(0, 0, 1),    # frente
	Vector3(1, 0, 0),    # direita  
	Vector3(0, 0, -1),   # atrás
	Vector3(-1, 0, 0),   # esquerda
	Vector3(0, 1, 0),    # cima
	Vector3(0, -1, 0),   # baixo
]

var face_atual := 0

func _ready() -> void:
	position = faces[face_atual] * distancia

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_right"):
		face_atual = (face_atual + 1) % faces.size()
	if Input.is_action_just_pressed("ui_left"):
		face_atual = (face_atual - 1 + faces.size()) % faces.size()

	position = position.lerp(faces[face_atual] * distancia, lerp_speed * delta)
	
	look_at(get_parent().global_position, Vector3.UP)
