extends Control
@onready var teclas := $"teclas-ajuda/animação-teclas"
@onready var cubo := $"cubo-girando/animação-cubo-girando"
@onready var camera := $"cenario/SubViewport/Node3D/Camera3D"

var girando := false

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")
	
func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _process(delta: float) -> void:
	teclas.play("teclas-mexendo")
	cubo.play(("cubo-girando"))

# transição
	if girando:
		return

	if Input.is_action_just_pressed("move_left"):
		girar_camera(90)

	elif Input.is_action_just_pressed("move_right"):
		girar_camera(-90)	

func girar_camera(angulo: float):
	girando = true
	var tween = create_tween()
	
	tween.tween_property(
		camera,
		"rotation:z",
		camera.rotation.z + deg_to_rad(angulo),
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	girando = false
