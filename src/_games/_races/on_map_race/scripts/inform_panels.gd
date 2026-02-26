extends PanelContainer

# UI Panels
@export var distance_challenge_inform_panel : PanelContainer
@export var time_trial_inform_panel : PanelContainer
@export var margin_container : MarginContainer

@export var audio_player: AudioStreamPlayer

func _on_timetrial_inform_button_pressed() -> void:
	margin_container.visible = true
	time_trial_inform_panel.visible = true
	audio_player.play()


func _on_distancechallenge_inform_button_pressed() -> void:
	margin_container.visible = true
	distance_challenge_inform_panel.visible = true
	audio_player.play()


func _on_time_trial_panel_cancel_button_pressed() -> void:
	margin_container.visible = false
	time_trial_inform_panel.visible = false
	audio_player.play()


func _on_distance_challenge_cancel_button_pressed() -> void:
	margin_container.visible = false
	distance_challenge_inform_panel.visible = false
	audio_player.play()
