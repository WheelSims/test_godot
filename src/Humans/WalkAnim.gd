extends Node3D  # Ce script est optionnel si tu veux jouer une anim à l'init

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready():
	anim_player.play("Walking")  # Nom exact de ton anim Mixamo
