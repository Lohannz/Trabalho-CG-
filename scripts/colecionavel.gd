extends Area3D

static var total: int = 0

@onready var mesh = $mesh_livro
@onready var collision = $CollisionShape3D
@onready var camera : Camera3D = get_tree().current_scene.get_node("Camera3D")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		total += 1
		_coletar()

func _process(_delta: float) -> void:
	rotate(camera._orientation.y, deg_to_rad(1))
	
func _coletar() -> void:
	mesh.visible = false
	collision.set_deferred("disabled", true)
	get_tree().call_group("contador_ui", "atualizar", total)
