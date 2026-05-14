extends Node

@export var UDP_RECEIVE_PORT: int = 1511

var _udp_receiver = PacketPeerUDP.new()
var _udp_receiver_connected = false
var data # Payload of the UDP packet

# General UDP packet information
var message_id
var packet_size
var current_frame
var marker_set_count
var unlabeled_markers_count
var rigid_body_count

var id_rigidbodies = [] # List of rigidbody IDs seen


func _ready():
	_udp_receiver.bind(UDP_RECEIVE_PORT)


func _process(_delta):
	var debut = Time.get_ticks_usec()
	if _udp_receiver.get_available_packet_count() > 0: # We received something
		if not _udp_receiver_connected:
			_udp_receiver_connected = true
		data = _udp_receiver.get_packet()

		# Discard everything until the very last packet we received
		while _udp_receiver.get_available_packet_count() > 0:
			data = _udp_receiver.get_packet()

		# Get general information from the UDP packet
		message_id = PackedByteArray(data.slice(0, 2)).decode_s16(0)
		packet_size = PackedByteArray(data.slice(2, 4)).decode_s16(0)
		current_frame = PackedByteArray(data.slice(4, 8)).decode_s32(0)
		marker_set_count = PackedByteArray(data.slice(8, 12)).decode_s32(0)
		unlabeled_markers_count = PackedByteArray(data.slice(12, 16)).decode_s32(0)
		rigid_body_count = PackedByteArray(data.slice(16, 20)).decode_s32(0)

		# Send positions and rotations for each rigid body
		for i in range(rigid_body_count):
			var result = unpack_rigid_body(data, i)

			# Positions and rotations
			var id_num = result[0]
			var pos = result[1] # Vector3 positions (x,y,z) of the centroid
			var rot = result[2] # Quaternion (x,y,z,w)

			# Mean position error
			var _mean_error = result[3]

			# Boolean flag indicating if the rigid body is tracked by the cameras
			var _tracked = result[4]

			# Add a rigid body node and assign its ID as its name
			if not has_node(str(id_num)):
				var node = Node3D.new()
				node.name = str(id_num)
				add_child(node)

			# Update the position and rotation of the rigid body node
			self.get_node(str(id_num)).position = pos
			self.get_node(str(id_num)).quaternion = rot

			# Hide rigid body node if it is not tracked by the cameras
			self.get_node(str(id_num)).visible = _tracked

		# Remove rigid body nodes that are no longer tracked
		for child in get_children():
			if child.name not in id_rigidbodies:
				child.queue_free()

		# Clear the list of seen rigid body IDs for each iteration
		id_rigidbodies.clear()

	if not Config.get_value("devices.optitrack.enabled"):
		queue_free()
	var fin = Time.get_ticks_usec()
	var temp_execution = (fin - debut)/1_000_000.0
	print("Temps d'exécution optitrack.gd : %.6f secondes" % temp_execution)

## Parse UDP packet.
func get_message_id(_data):
	message_id = PackedByteArray(_data.slice(0, 2)).decode_s16(0)
	return message_id


## Get position/rotation/status of body i_rigidbody
func unpack_rigid_body(_data, i_rigidbody):
	var offset = i_rigidbody * 38 + 20
	# Offset 20 since rigid body data begins after the header

	# Streaming ID
	var _id_num = PackedByteArray(_data.slice(offset, offset + 4)).decode_s32(0)
	offset += 4

	# Centroid positions
	var pos_x = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4
	var pos_y = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4
	var pos_z = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4
	var _pos = Vector3(pos_x, pos_y, pos_z)

	# Orientations
	var rot_x = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4
	var rot_y = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4
	var rot_z = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4
	var rot_w = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4
	var _rot = Quaternion(rot_x, rot_y, rot_z, rot_w).normalized()

	# Mean error
	var _error = PackedByteArray(_data.slice(offset, offset + 4)).decode_float(0)
	offset += 4

	# Boolean flag: 1 if the marker is visible to the cameras
	var _tracked = PackedByteArray(_data.slice(offset, offset + 2)).decode_s16(0)
	offset += 2

	# Track rigid body IDs in a list
	if _id_num not in id_rigidbodies:
		id_rigidbodies.append(str(_id_num))

	return [_id_num, _pos, _rot, _error, _tracked]


## Get rigid body node using its integer ID
func get_node_by_id(id):
	if has_node(str(id)):
		return get_node(str(id))


## Debug overlay
func get_debug_text() -> String:
	var text = ""
	text += "Cameras "
	if not _udp_receiver_connected:
		text += "not "
	text += "connected.\n"
	return text
