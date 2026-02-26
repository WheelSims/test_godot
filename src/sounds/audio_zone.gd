extends Area3D

@export var audio_mixer_bus_name: String
var bus_index = AudioServer.get_bus_index(audio_mixer_bus_name)
@export var fade_duration = 5

func _ready()->void:
	bus_index = AudioServer.get_bus_index(audio_mixer_bus_name)
	_set_bus_volume(-80)
	
func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_fade_in()

func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_fade_out()
		
func _fade_in():
	var tween = create_tween()
	tween.tween_method(_set_bus_volume, -80,  0.0, fade_duration)

func _fade_out():
	var tween = create_tween()
	tween.tween_method(_set_bus_volume, 0.0,  -80, fade_duration)
	

func _set_bus_volume(volume_db: float):
	AudioServer.set_bus_volume_db(bus_index, volume_db)
