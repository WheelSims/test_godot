@tool
extends EditorScript
## object_size_baker convert the scenes passed in the bake_config inspector to [ObjectInfo] objects.
## to use it: right click on the script -> Execute or Ctrl+Shift+X

var config: BakeConfig = load("res://games/races/obstacle_race/generator/baker/bake_config_res.tres")

func _run():
	var objects_to_bake: Array[PackedScene] = config.objects_to_bake
	for scene in objects_to_bake:
		var instance = scene.instantiate()
		EditorInterface.get_edited_scene_root().add_child(instance)

		instance.force_update_transform()
		var object_info = ObjectInfo.new()
		if instance is WorldScaleCalculator:
			object_info.scene = scene
			var inst: WorldScaleCalculator = instance
			inst.get_precise_size()
			object_info.type = inst.object_type
			if inst.object_type == WorldScaleCalculator.ObjectType.Obstacle:
				object_info.sizes = inst.write_sizes_with_rotation([90, 45, -45, 0])
			else:
				object_info.sizes = inst.write_sizes_with_rotation()
			object_info.local_scale = inst.get_size()
		else:
			push_error("The PackedeScene %s is not a WorldScaleCalculator" %scene.resource_name)
		
		if not DirAccess.dir_exists_absolute(config.object_info_folder_path):
			DirAccess.make_dir_recursive_absolute(config.object_info_folder_path)
			
		var path = config.object_info_folder_path + instance.name + ".tres"
		object_info.take_over_path(path)
		ResourceSaver.save(object_info, path)
		EditorInterface.get_resource_filesystem().scan()
		print(path)

		instance.queue_free()
