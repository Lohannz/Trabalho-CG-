extends Control


func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
