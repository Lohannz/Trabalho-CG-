extends Label

func _ready() -> void:
	add_to_group("contador_ui")
	atualizar(0)

func atualizar(total: int) -> void:
	text = "Coletados: %d" % total
