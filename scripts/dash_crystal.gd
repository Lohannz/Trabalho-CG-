extends Area3D

@onready var mesh = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D
@onready var respawn_timer = $RespawnTimer

func _ready() -> void:
	# Conectando os sinais via código
	body_entered.connect(_on_body_entered)
	respawn_timer.timeout.connect(_on_respawn_timeout)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("restore_dash"):
		body.restore_dash()
		_coletar_cristal()

func _coletar_cristal() -> void:
	# Esconde o visual do cristal
	mesh.visible = false
	
	# Desativa a área de colisão para o player não pegar repetidas vezes
	# O set_deferred é obrigatório no Godot para desativar colisões com segurança durante a física
	collision_shape.set_deferred("disabled", true)
	
	# Inicia o tempo de recarga
	respawn_timer.start()

func _on_respawn_timeout() -> void:
	# O tempo acabou! Reativa o visual e a colisão do cristal
	mesh.visible = true
	collision_shape.set_deferred("disabled", false)
