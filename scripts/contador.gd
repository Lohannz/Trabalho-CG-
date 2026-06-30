extends HBoxContainer

@onready var label := $Contador
@onready var icon_modelo := $icon_livro

func _ready():
	add_to_group("contador_ui")
	atualizar(0)
	var icon = TextureRect.new()
	icon.texture = textura_item
	icon.custom_minimum_size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	add_child(icon)

var textura_item = preload("res://sprites/icon_livro_coletavel.png")
var quantidade_atual := 0

func atualizar(total: int):
	label.text = str(total) + "×"
