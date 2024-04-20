# Experimental!

~ "lib.ua"
  ~ ConnectToWebsocket‼
  ~ GetWebsocketMessageData
  ~ SendText

$ ws://127.0.0.1:8080/
ConnectToWebsocket‼(
  ⍢(
    &p $"Received: _" GetWebsocketMessageData recv 0
  )1
| ⍢(
    SendText ⟜(&p $"Sending: _") &sc
  )1
)
