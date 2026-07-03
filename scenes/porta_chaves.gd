extends Node3D
class_name PortaChaves

@export var total_chaves: int = 4

@onready var luzes: Array[MeshInstance3D] = [
	$Luzes/MeshInstance3D,
	$Luzes/MeshInstance3D2,
	$Luzes/MeshInstance3D3,
	$Luzes/MeshInstance3D4,
]

# Crie um Area3D filho de "portaV2" chamado "AreaInteracao" (com um
# CollisionShape3D do tamanho da área em que o jogador pode interagir).
@onready var area_interacao: Area3D = $Area3D

var chaves_colocadas: int = 0
var _jogador_por_perto: CharacterBody3D = null

func _ready() -> void:
	_atualizar_luzes()
	area_interacao.body_entered.connect(_on_area_interacao_body_entered)
	area_interacao.body_exited.connect(_on_area_interacao_body_exited)

func _on_area_interacao_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_jogador_por_perto = body

func _on_area_interacao_body_exited(body: Node3D) -> void:
	if body == _jogador_por_perto:
		_jogador_por_perto = null

func _unhandled_input(event: InputEvent) -> void:
	if _jogador_por_perto == null:
		return
		
	if event.is_action_pressed("ui_F"):
		colocar_chaves()

func colocar_chaves() -> void:
	if chaves_colocadas >= total_chaves:
		return

	var disponiveis := Chave.chaves_seguindo
	if disponiveis <= 0:
		return

	var espaco_restante := total_chaves - chaves_colocadas
	var usadas = min(disponiveis, espaco_restante)

	Chave.entregar_chaves(usadas)
	chaves_colocadas += usadas
	_atualizar_luzes()

	if chaves_colocadas >= total_chaves:
		_abrir_porta()

func _atualizar_luzes() -> void:
	for i in luzes.size():
		var material := luzes[i].get_active_material(0) as StandardMaterial3D
		if material == null:
			continue
		material.emission_energy_multiplier = 16.0 if i < chaves_colocadas else 0.0
		print("entrou")

func _abrir_porta() -> void:
	print("Porta destrancada! Todas as chaves foram colocadas.")
