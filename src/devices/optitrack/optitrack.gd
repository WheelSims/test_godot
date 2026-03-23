extends Node
@onready var main: Node = get_tree().get_root().get_node("main")

@export var UDP_RECEIVE_PORT: int = 1511

var _udp_receiver = PacketPeerUDP.new()
var _udp_receiver_connected = false
var data # Contenu du paquet UDP

# Informations générales du paquet UDP
var message_id
var packet_size
var current_frame
var marker_set_count
var unlabeled_markers_count
var rigid_body_count

var id_rigidbodies = []


func _ready():
	_udp_receiver.bind(UDP_RECEIVE_PORT)

func _process(_delta):

	if _udp_receiver.get_available_packet_count() > 0:  # We received something
		if not _udp_receiver_connected:
			_udp_receiver_connected = true
		data = _udp_receiver.get_packet()

		# Discard everything until the very last packet we received
		while _udp_receiver.get_available_packet_count() > 0:
			data = _udp_receiver.get_packet()

		# Informations générales du paquet UDP
		message_id = get_message_id(data)
		packet_size = get_packet_size(data)
		current_frame = get_current_frame(data)
		marker_set_count = get_marker_set_count(data)
		unlabeled_markers_count = get_unlabeled_markers_count(data)
		rigid_body_count = get_rigid_body_count(data)

		# Transmission des positions et orientations à chaque rigibody
		for i in range(rigid_body_count):
			
			var result = unpack_rigid_body(data, i)
			
			## Positions et rotations
			var id_num = result[0]
			var pos = result[1] # Vector3 positions (x,y,z) du centroïde
			var rot = result[2] # Quaternion (x,y,z,w)

			# Erreur moyenne de la position
			var _mean_error = result[3]
			
			# Booleen si le corps rigidbody est capturé par les caméras
			var _tracked = result[4]

			if not has_node(str(id_num)):
				var node = Node3D.new()
				node.name = str(id_num)
				add_child(node)
			
			self.get_node(str(id_num)).position = pos
			self.get_node(str(id_num)).quaternion = rot
		
		for child in get_children():
			if child.name not in id_rigidbodies:
				child.queue_free()
		
		id_rigidbodies.clear()

	if main:
		if not main.config.get_value("devices.optitrack.enabled"):
			queue_free()

func get_message_id(_data):
	message_id = PackedByteArray(_data.slice(0, 2)).decode_s16(0)
	return message_id
func get_packet_size(_data):
	packet_size = 0
	var offset = 2
	
	packet_size = PackedByteArray(_data.slice(offset , offset+2)).decode_s16(0)
	return packet_size
func get_current_frame(_data):
	current_frame = 0
	var offset = 4
	
	current_frame = PackedByteArray(_data.slice(offset , offset+4)).decode_s32(0)
	
	return current_frame
func get_marker_set_count(_data):
	marker_set_count = 0
	var offset = 8
	
	marker_set_count = PackedByteArray(_data.slice(offset , offset+4)).decode_s32(0)
	return marker_set_count
func get_unlabeled_markers_count(_data):
	unlabeled_markers_count = 0
	var offset = 12
	
	unlabeled_markers_count = PackedByteArray(_data.slice(offset , offset+4)).decode_s32(0)
	return unlabeled_markers_count
func get_rigid_body_count(_data):
	rigid_body_count = 0
	var offset = 16
	
	rigid_body_count = PackedByteArray(_data.slice(offset , offset+4)).decode_s32(0)
	return rigid_body_count

func unpack_rigid_body(_data, n_rigidbody):
	
	var offset = n_rigidbody*38 + 20 
	# 20  car les informations concernant les rigibodies commencent après le header
	
	# Numéro Streaming ID
	var _id_num = PackedByteArray(_data.slice(offset , offset+4)).decode_s32(0)
	offset += 4

	# Positions du centroïde
	var pos_x = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)		
	offset += 4
	var pos_y = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)
	offset += 4
	var pos_z = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)
	offset += 4
	var _pos = Vector3(pos_x, pos_y, pos_z)
	
	# Orientations
	var rot_x = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)
	offset += 4
	var rot_y = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)
	offset += 4
	var rot_z = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)
	offset += 4
	var rot_w = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)
	offset += 4
	var _rot = Quaternion(rot_x, rot_y, rot_z, rot_w).normalized()

	# Erreur moyenne
	var _error = PackedByteArray(_data.slice(offset , offset+4)).decode_float(0)
	offset += 4
	
	# Etat booléen : 1 si le marqueur est visible par les caméras
	var _tracked = PackedByteArray(_data.slice(offset , offset+2)).decode_s16(0)
	offset += 2
	
	
	# Ajouter les id dans un dictionnaire pour les faire correspondre aux rigidbodies
	if _id_num not in id_rigidbodies:
		id_rigidbodies.append(str(_id_num))

	
	# Afficher les informations dans la console
	#var _current_frame = get_current_frame(data)
	#if _current_frame % 100 == 0:
		#print("\n \n\nFRAME : ", _current_frame)
		#print("id_num     : ", _id_num)
		#print("pos        : ", _pos)
		#print("rot        : ", _rot)
		#print("error      : ", _error)
		#print("tracked    : ", _tracked)
	
	return [_id_num, _pos, _rot, _error, _tracked]


func get_node_by_id(id):
	if has_node(str(id)):
		return get_node(str(id))

func get_debug_text() -> String:
	var text = ""
	text += "Cameras "
	if not _udp_receiver_connected:
		text += "not "
	text += "connected.\n"
	return text
