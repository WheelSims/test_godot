extends Node

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

var id_rigidbodies = {}
var n_id = 0

func _ready():
	_udp_receiver.bind(UDP_RECEIVE_PORT)

func _process(_delta):

	

	#print(_udp_receiver.get_available_packet_count())
	if _udp_receiver.get_available_packet_count() > 0:  # We received something
		if not _udp_receiver_connected:
			_udp_receiver_connected = true
			print("System Optitrack connected.")
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

		
		# WIP
		# recuperation de la position du centre de la roue dans le repere global a automatiser
		var pos_center_wheel_right = Vector3(-0.602935, 0.39298, 0.039214)

			
		# Transmission des positions et orientations à chaque rigibody
		for i in range(5): ## nombre de rigidbody enfants écrit en clair pour l'instant
			if i+1 > rigid_body_count: # s'il y a trop de nodes 3D que de rigibodies détectés
				self.get_node("rigid_body_" + str(i)).scale = Vector3(0, 0, 0)
				
			else: # afficher les rigidbodies et appliquer leurs translations et rotations
				self.get_node("rigid_body_" + str(i)).scale = Vector3(1, 1, 1)

				# Positions et rotations
				var result = unpack_rigid_body(data, i)
				var pos = result[1] # Vector3 positions (x,y,z) du centroïde
				var rot = result[2] # Quaternion (x,y,z,w)
				self.get_node("rigid_body_" + str(i)).position = pos
				self.get_node("rigid_body_" + str(i)).quaternion = rot
				
				# WIP
				var TS0 = get_transform_matrix_by_id(102)
				if TS0 != null: 
					var T0S = TS0.affine_inverse()
					
					var _pos_center_wheel_right = T0S.origin + T0S.basis * pos_center_wheel_right
					
					if id_rigidbodies[102] != "rigid_body_" + str(i):
						# Objet_global → Objet_dans_repere_local
						get_node("rigid_body_" + str(i)).global_transform =  T0S * get_node("rigid_body_" + str(i)).global_transform
						
						#get_node("rigid_body_" + str(i)).position -= _pos_center_wheel_right
						if id_rigidbodies[102] != "rigid_body_" + str(i) and id_rigidbodies[302] != "rigid_body_" + str(i):
							get_node("rigid_body_" + str(i)).position -= _pos_center_wheel_right 
							get_node("rigid_body_" + str(i)).position += Vector3(0, 0, 0.3)

				# Erreur moyenne de la position
				var _mean_error = result[3]

				# Couleur rouge si le rigidbody n'est plus détecté
				var tracked = result[4]
				var mat = StandardMaterial3D.new()
				if tracked == 0:
					mat.albedo_color = Color(1, 0, 0)
				else:
					mat.albedo_color = Color(1, 1, 1)
				self.get_node("rigid_body_" + str(i)).get_node("MeshInstance3D").material_override = mat

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
	
	var offset = n_rigidbody*38 + 20 # 20 -> car 
	# les informations concernant les rigibodies commencent après le header
	
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
		id_rigidbodies[_id_num] = "rigid_body_" + str(n_id)
		n_id += 1
	
	
	# Afficher les informations dans la console
	#var _current_frame = get_current_frame(data)
	#if _current_frame % 10 == 0:
		#print("\n \n\nFRAME : ", _current_frame)
		#print("id_num     : ", _id_num)
		#print("pos        : ", _pos)
		#print("rot        : ", _rot)
		#print("error      : ", _error)
		#print("tracked    : ", _tracked)
	
	return [_id_num, _pos, _rot, _error, _tracked]


func get_position_by_id(id):
	if id in id_rigidbodies:
		return get_node(id_rigidbodies[id]).position

func get_transform_matrix_by_id(id):
	if id in id_rigidbodies:
		return get_node(id_rigidbodies[id]).global_transform
