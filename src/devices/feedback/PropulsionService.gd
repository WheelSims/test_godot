# manages UDP communication between Godot and the Python script PropulsionDetection.py

extends Node
# Network setup
var socket = PacketPeerUDP.new()
var python_ip = "127.0.0.1"
var port_to_python = 5052
var port_from_python = 5053

# Recording time in seconds
var recording_duration = 60.0

# Internal state
var _recording = false

signal score_received(percentage)

func _ready():
	if socket.bind(port_from_python) != OK:
		print("Erreur : Unable to link the port ", port_from_python)
	else:
		print("Propulsion service ready. Listening on the port ", port_from_python)

	# Wait 3 seconds for Python to be fully ready
	await get_tree().create_timer(3.0).timeout
	start_recording()

	await get_tree().create_timer(recording_duration).timeout
	stop_and_get_results()


# Send Record continuously while recording
func _process(_delta):
	if _recording:
		var message = "Record,Joueur1,1,1"
		socket.set_dest_address(python_ip, port_to_python)
		socket.put_packet(message.to_utf8_buffer())

	# Constantly checking for the arrival of new packets
	if socket.get_available_packet_count() > 0:
		var data = socket.get_packet().get_string_from_utf8()
		_handle_python_data(data)

#Processes the raw data received from the Python script
func _handle_python_data(data: String):
	print("Data received from Python : ", data)
	emit_signal("score_received", data)

#Sends a formatted command to the Python script via UDP
func send_command(command_type: String, user_name: String = "GodotPlayer"):
	var message = "%s,%s,1,1" % [command_type, user_name]
	socket.set_dest_address(python_ip, port_to_python)
	var error = socket.put_packet(message.to_utf8_buffer())
	if error == OK:
		print("Order sent : ", message)
	else:
		print("Sending error")
		
#Activates the recording state in Godot
func start_recording():
	_recording = true
	print(">>> Recording started automatically")

#Stop local recording and ask Python to send the final results
func stop_and_get_results():
	_recording = false
	var message = "SendResults,Joueur1,1,1"
	socket.set_dest_address(python_ip, port_to_python)
	socket.put_packet(message.to_utf8_buffer())
	print(">>> Registration complete, results sent")
