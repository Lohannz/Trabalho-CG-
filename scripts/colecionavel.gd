extends Area3D

static var total: int = 0

@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		total += 1
		_coletar()

func _coletar() -> void:
	mesh.visible = false
	collision.set_deferred("disabled", true)
	get_tree().call_group("contador_ui", "atualizar", total)
