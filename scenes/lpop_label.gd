extends Label

@export var escala_maxima := 1.35
@export var tempo := 0.15

func _process(delta: float) -> void:
	pop()
func pop():
	scale = Vector2.ZERO

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE * escala_maxima,
		tempo * 0.6
	)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		tempo * 0.4
	)
