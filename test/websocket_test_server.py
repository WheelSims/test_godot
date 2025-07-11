# !/usr/bin/env python

# This file starts a websocket server on localhost, port 8765, and
# prints what it receives. This is a tool to check that Godot is
# streaming data accordingly, for instance to debug the DBox controller.


import asyncio
from websockets.asyncio.server import serve

async def echo(websocket):
    async for message in websocket:
    	print(message)
        #await websocket.send(message)

async def main():
    async with serve(echo, "localhost", 8765) as server:
        await server.serve_forever()

asyncio.run(main())
