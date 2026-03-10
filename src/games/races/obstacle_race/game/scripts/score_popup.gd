extends Control

@onready var label: Label = $Label

func show_score(value: int):

	label.text = "+" + str(value)

	var tween = create_tween()

	# montée du texte
	tween.tween_property(self, "position:y", position.y - 60, 0.8)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	# fade out
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)

	# petit effet de scale au début
	label.scale = Vector2(0.6,0.6)
	tween.parallel().tween_property(label, "scale", Vector2(1,1), 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished
	queue_free()
