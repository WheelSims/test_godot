import socket
import json
import time
import importlib
import sys
import threading


UDP_IP = "127.0.0.1"
PYTHON_PORT = 4243
GODOT_PORT = 4242

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

sock.settimeout(1.0)

sock.bind((UDP_IP, PYTHON_PORT))

running = True


# basics functions
def function_1(arg = "argument"):
    _send_data(str(arg))
        
def function_2():
    _send_data({"data": "hello"})

def function_3():
    _send_data({"type": "response", "data": "hello"})


# Close this Python app
def close():
    global running
    print("\nClose Python app...")
    time.sleep(2)
    running = False


# functions to call anything command : Godot to Python
command = {"function_1": function_1,
           "function_2": function_2,
           "function_3": function_3,
           "close": close}

def call_command(_json):

    _command = _json.get("command")
    _arg = _json.get("arg")

    try:
        func = command[_command]
        if _arg is not None:
            func(_arg)
        else:
            func()
        print("request received : ", _command)
    except:
        print("la fonction n'existe pas")


# Bridge functions UDP : Python to Godot
def _send_data(data):    

    try:
        message = json.dumps(data).encode("utf-8")
        sock.sendto(message, (UDP_IP, GODOT_PORT))

    except KeyboardInterrupt:
        pass


# Main
try:
    
    # Sending ping request, availables functions to Godot for debug scene
    print("Python connected to Godot...\n")
    time.sleep(1)
    _send_data(list(command.keys()))
    
    # Listening Godot requests
    while running:
        try:
            
            message, address = sock.recvfrom(1024)
            commande = message.decode("utf-8")
            commande = json.loads(commande)

            call_command(commande)

        except socket.timeout:
            continue
except KeyboardInterrupt:
    pass
finally:
    sock.close()
