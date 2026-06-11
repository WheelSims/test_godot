## Generate a number of pedestrians located in random places of the walkable area of the scene.

extends Node3D

## Number of pedestrians to generate
@export var n_pedestrians : int = 20

## The humans, e.g. brian.tscn, josh.tscn
@export var humans : Array[PackedScene]

@export var pedestrian : PackedScene

@onready var map_ready: bool = false


func _ready() -> void:
	for i in range(n_pedestrians):
		var one_pedestrian = pedestrian.instantiate()
		one_pedestrian.spawn_on_random_point = true
		one_pedestrian.walking_speed = randf_range(0.8, 3.5)
		add_child(one_pedestrian)

		var one_human = humans[randi_range(0, len(humans)-1)]
		one_pedestrian.add_child(one_human.instantiate())
