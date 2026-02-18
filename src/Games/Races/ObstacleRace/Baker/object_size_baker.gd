@tool
extends EditorScript

var config: BakeConfig = load("res://Games/Races/ObstacleRace/Baker/bake_config_res.tres")

func _run():
	var objects_to_bake: Array[PackedScene] = config.objects_to_bake
	for scene in objects_to_bake:
		var instance = scene.instantiate()
		get_editor_interface().get_edited_scene_root().add_child(instance)

		instance.force_update_transform()
		if instance is WorldScaleCalculator:
			var inst: WorldScaleCalculator = instance
			inst.get_precise_size_z()
			if inst.object_type == WorldScaleCalculator.ObjectType.Obstacle:
				inst.write_sizes_with_rotation([90, 45, -45, 0])
		#instance.baked_size_z = size
		scene.pack(instance)
		ResourceSaver.save(scene)

		instance.queue_free()
