extends Area3D

@export var audio_mixer_bus_name: String
@export var fade_duration = 5
@onready var bus_index = AudioServer.get_bus_index("Environment")


func _ready() -> void:
	_set_bus_volume(-80)


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_fade_in()


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_fade_out()


func _fade_in():
	var tween = create_tween()
	tween.tween_method(_set_bus_volume, -80, 0.0, fade_duration)


func _fade_out():
	var tween = create_tween()
	tween.tween_method(_set_bus_volume, 0.0, -80, fade_duration)


func _set_bus_volume(volume_db: float):
	print(AudioServer.get_bus_index("Environment"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Environment"), volume_db)
