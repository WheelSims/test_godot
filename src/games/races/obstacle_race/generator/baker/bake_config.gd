class_name BakeConfig
extends Resource
## BakeConfig defines a resource that stocks objects to bake with baker object_size_baker.

@export var objects_to_bake: Array[PackedScene]
## The destination folder of the futur object infos.
@export var object_info_folder_path = "res://games/races/obstacle_race/generator/object_infos_resources/"
