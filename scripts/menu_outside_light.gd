extends Node3D

@export_category("Configurações da Luz")
@export var cor_especifica: Color = Color.CYAN
@export var velocidade_rotacao: float = 3.0
@export var energia_base: float = 1.0
@export var energia_ao_encostar: float = 5.0

@onready var luz_x := $SpotLight3D_1
@onready var luz_y := $SpotLight3D_2
@onready var luz_z := $SpotLight3D_3
@onready var area_de_contato := $Area3D

func _ready() -> void:
	# 1. Aplica a cor específica em todas as luzes
	luz_x.light_color = cor_especifica
	luz_y.light_color = cor_especifica
	luz_z.light_color = cor_especifica
	
	# 2. Força o alinhamento perpendicular exato (Eixos X, Y e Z)
	luz_x.rotation_degrees = Vector3(0, 90, 0)   # Aponta para a direita
	luz_y.rotation_degrees = Vector3(-90, 0, 0)  # Aponta para cima
	luz_z.rotation_degrees = Vector3(0, 0, 0)    # Aponta para frente
	
	# 3. Conecta o sinal de encostar automaticamente via código
	area_de_contato.body_entered.connect(_ao_encostar_em_algo)

func _process(delta: float) -> void:
	# Faz o nó pai girar continuamente, levando as 3 luzes junto
	# Adicionei rotação em X e Y para um efeito de giro esférico completo
	rotate_y(velocidade_rotacao * delta)
	rotate_x((velocidade_rotacao / 2.0) * delta)

# Função que age nos objetos que você encosta
func _ao_encostar_em_algo(body: Node3D) -> void:
	# Opcional: Você pode checar se é um inimigo ou objeto específico
	# if body.is_in_group("inimigo"):
	
	# Exemplo de ação: Dá um "flash" de luz quando encosta em algo
	luz_x.light_energy = energia_ao_encostar
	luz_y.light_energy = energia_ao_encostar
	luz_z.light_energy = energia_ao_encostar
	
	# Cria um efeito suave (Tween) para a luz voltar ao normal rapidamente
	var tween = create_tween().set_parallel(true)
	tween.tween_property(luz_x, "light_energy", energia_base, 0.5)
	tween.tween_property(luz_y, "light_energy", energia_base, 0.5)
	tween.tween_property(luz_z, "light_energy", energia_base, 0.5)
