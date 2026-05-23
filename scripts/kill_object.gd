extends Node3D
@onready var nodes = get_children()

## Node que vai verificar se o player entrou em uma area que pode matar ele. 
## ao entrar na area, chama o método die() do player
var areas = []
func _ready() -> void:
	for node in get_children():
		for child in node.get_children():
			if child is Area3D:
				child.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "player":
		body.die()
