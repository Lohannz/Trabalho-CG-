extends Control

@export var escala_pop := 1.3
@export var escala_normal := 1.0

@export var tempo_pop := 0.12
@export var atraso_entre_letras := 0.04
@export var espera_entre_animacoes := 2.99


func _ready():
	animacao_loop()

func animacao_loop() -> void:
	while true:
		for palavra in get_children():
			if palavra is VBoxContainer:
				await animar_palavra(palavra)

		await get_tree().create_timer(espera_entre_animacoes).timeout


func animar_palavra(vbox: VBoxContainer) -> void:

	for letra in vbox.get_children():
		if letra is Label:
			var tween = create_tween()
			tween.tween_property(
				letra,
				"scale",
				Vector2.ONE * escala_pop,
				tempo_pop
			)

			tween.tween_property(
				letra,
				"scale",
				Vector2.ONE,
				tempo_pop
			)

			await get_tree().create_timer(atraso_entre_letras).timeout
