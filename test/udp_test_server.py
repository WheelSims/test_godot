"""
An UDP server monitor to debug the simulator.

Author: Félix Chénier
"""

import socket

ip = "127.0.0.1"
port = 25000
buffer_size = 100

udp_socket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)

udp_socket.bind((ip, port))

print("Listening...")

while True:
    contents = udp_socket.recvfrom(buffer_size)
    message = contents[0]
    address = contents[1]

    print(f"{address} sent {len(message)} bytes: {message}")
