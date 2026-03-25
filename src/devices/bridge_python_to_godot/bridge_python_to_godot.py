import socket
import json
import time
import importlib

UDP_IP = "127.0.0.1"
PYTHON_PORT = 4243
GODOT_PORT = 4242

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

sock.settimeout(1.0)

sock.bind((UDP_IP, PYTHON_PORT))

print("Python connected to Godot...")


# basics functions
def fonction_test():
    print("\nrequest received...")
    _send_data({"type": "response", "data": "hello"})
    print("response sent to Godot : hello")


# functions to call anything command : Godot to Python
command = {"fonction_test": fonction_test}


def call_command(_json):

    _module = _json.get("module")
    _command = _json.get("command")
    _arg = _json.get("arg")

    try:
        if _module is None:
            func = command[_command]

        if _arg is not None:
            func(_arg)
        else:
            func()
    except:
        print("la fonction n'existe pas")


# Bridge functions UDP : Python to Godot
def _send_data(data):

    try:
        message = json.dumps(data).encode("utf-8")
        sock.sendto(message, (UDP_IP, GODOT_PORT))

    except KeyboardInterrupt:
        pass


# Listening Godot requests
try:
    while True:
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
