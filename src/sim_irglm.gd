extends Node3D

@onready var second_window := $SecondDisplayWindow
@onready var second_camera := $SecondDisplayWindow/SubViewportContainer/SubViewport/CameraRig2/SecondCamera
@onready var player_camera_bas := $Player/Camera3DBas

func _ready():
	if DisplayServer.get_screen_count() > 1:
		# Met la fenêtre Godot principale sur Display 1
		DisplayServer.window_set_current_screen(0, 0)
		# Met la fenêtre secondaire sur Display 2
		second_window.set_current_screen(1)

	# Force la caméra secondaire à afficher ce que voit Camera3DBas
	second_camera.current = true
	second_camera.global_transform = player_camera_bas.global_transform

func _process(delta):
	second_camera.global_transform = player_camera_bas.global_transform
