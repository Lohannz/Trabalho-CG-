extends Control
@onready var teclas := $"teclas-ajuda/animação-teclas"

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _process(delta: float) -> void:
	teclas.play("teclas-mexendo")
func _on_exit_button_pressed() -> void:
	get_tree().quit()
