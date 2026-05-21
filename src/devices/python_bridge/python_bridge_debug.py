import socket
import json
import time
import importlib
import sys
import threading
# imports for trajectory data logging
import os
from datetime import date
import csv
import glob

# setting up the data logging folder and participant name
data_folder = r'D:\Maria_school\Documents\S2026\data'
participant = 'test'
folder = os.path.join(data_folder, participant)
# creating a folder if it does not exist
if not os.path.exists(folder):
    os.makedirs(folder)
    session = '0'
else:
    # determining which session number we should write to (to not over-write data)
    files = glob.glob(os.path.join(folder, '*.csv'))
    if(len(files))>0:
        sessions = [int(file.split('\\')[-1].split('_')[0].split('S')[1]) for file in files]
        session = str(max(sessions)+1)
    else:
        session = '0'

UDP_IP = "127.0.0.1"
PYTHON_PORT = 4243
GODOT_PORT = 4242

# this creates a socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

# without this, thread is blocked until message is received
sock.settimeout(1.0)

# this binds a socket with the UDP IP and the python poty
sock.bind((UDP_IP, PYTHON_PORT))

# for a while True loop (keep collecting data)
running = True

# list to save trajectory data received
trajectory = []

# basics functions
def function_1(arg = "argument"):
   _send_data(str(arg))
        
def function_2():
    _send_data({"data": "hello"})

def function_3():
    _send_data({"type": "response", "data": "hello"})

def get_trajectory(arg):
    global trajectory
    trajectory.append(list(arg.values()))
    
def save_trajectory(trajectory):
    with open(os.path.join(folder, 'S'+session+'_'+str(date.today())+'.csv'), 'w', newline='') as file:
            writer = csv.writer(file) 
            writer.writerows(trajectory) 
    #print("done saving")

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
           "close": close,
           "trajectory": get_trajectory}

def call_command(_json):

    _command = _json.get("command")
    _arg = _json.get("arg")

    try:
        func = command[_command]
        if _arg is not None:
            func(_arg)
        else:
            func()
        if(_command!="trajectory"):
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
    time.sleep(0.1)
    _send_data(list(command.keys()))
    
    # Listening Godot requests
    while running:
        try:
            # buffer size = 1024 bytes
            message, address = sock.recvfrom(1024)
            # decode is used to ensure string compatibility
            commande = message.decode("utf-8")
            commande = json.loads(commande)
            
            call_command(commande)

        except socket.timeout:
            continue
 
except KeyboardInterrupt:
    pass
finally:
    print(trajectory)
    if len(trajectory)>0:
        save_trajectory(trajectory)
    sock.close()