extends Node2D

@onready var musicaMenu = $musica_Menu
@onready var musicaFase1 = $musica_Fase1
@onready var musicaFase2 = $musica_Fase2

func _ready() -> void:
	musicaMenu.finished.connect(func(): musicaMenu.play())
	musicaFase1.finished.connect(func(): musicaFase1.play())
	musicaFase2.finished.connect(func(): musicaFase2.play())
	musicaMenu.play()
	
func play(nome:String):

	musicaMenu.stop()
	musicaFase1.stop()
	musicaFase2.stop()

	match nome:
		"menu":
			musicaMenu.play()
		"fase1":
			musicaFase1.play()
		"fase2":
			musicaFase2.play()
