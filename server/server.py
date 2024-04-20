# import asyncio
# import websockets

# async def echo(websocket, path):
#     print("Client connected", flush=True)
#     await websocket.send("You are now connected to the server")

#     async for message in websocket:
#         print("Received and echoing message: " + message, flush=True)
#         await websocket.send(message)

# start_server = websockets.serve(echo, "0.0.0.0", 8080)

# print("WebSockets echo server starting", flush=True)
# asyncio.get_event_loop().run_until_complete(start_server)

# print("WebSockets echo server running", flush=True)
# asyncio.get_event_loop().run_forever()

import asyncio
import websockets

clients = set()  # A set to store connected clients

async def broadcast(message):
    """Broadcasts a message to all connected clients."""
    for client in clients:
        try:
            await client.send(message)
        except websockets.exceptions.ConnectionClosed:
            clients.remove(client)  # Remove disconnected clients

async def handler(websocket, path):
    """Handles a single WebSocket connection."""
    clients.add(websocket)  # Add the client to the set

    try:
        print("Client connected", flush=True)
        await websocket.send("You are now connected to the server")

        async for message in websocket:
            print("Received message: " + message, flush=True)
            await broadcast(message)  # Broadcast the message

    finally:
        clients.remove(websocket)  # Remove the client when it disconnects

start_server = websockets.serve(handler, "0.0.0.0", 8080)

print("WebSocket broadcast server starting", flush=True)
asyncio.get_event_loop().run_until_complete(start_server)

print("WebSocket broadcast server running", flush=True)
asyncio.get_event_loop().run_forever()