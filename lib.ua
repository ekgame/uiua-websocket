# Experimental!

~ "git: github.com/ekgame/uiua-http"
  ~ Body Header Method Protocol Url
  ~ BuildRequest! FormatHttpRequest ParseHttpResponse

Uri ~ "git: github.com/ekgame/uiua-uri-parser"

~ "./struct.ua" ~ Struct!

OpcodeContinuation ← 0
OpcodeText ← 1
OpcodeBinary ← 2
OpcodeClose ← 8
OpcodePing ← 9
OpcodePong ← 10

Struct!(WsFrame|IsFinal|Opcode|MaskingKey|Payload)
Struct!(Private|WsFrameMetadata|IsMasked|PayloadLength)
BuildWsFrame! ← (
  EmptyWsFrame
  SetWsFrameIsFinal 1
  SetWsFrameOpcode OpcodeText
  ^!
)
BuildMaskedWsFrame! ← BuildWsFrame!(
  SetWsFrameMaskingKey [⍥(⌊×256⚂)4]
  ^!
)

FormatAddress ← $"_:_" ∩°□⊃(get "domain")(get "port")
StreamReadLine ← ↘¯2◌:⍢(⊂:⊙:&rs1.:)(¬≍ "\r\n" ⬚@ ↙¯2)""
ReadHttpResponse ← ◌:⍢(⊂:"\r\n"⊂:⊙:StreamReadLine.:)(¬≍ "\r\n\r\n" ⬚@ ↙¯4)""

WsToHttp ← (
  Uri~Parse
  ⟜FormatAddress
  get"schema".
  ⊗:{"ws" "wss"}.
  ⟨"http"◌|"https"◌|0⍤:0 $"invalid schema: _"⟩
  insert "schema"
  Uri~Build
)

CreateWebsocketConnection ← (
  WsToHttp
  # TODO: Call &tlsc if schema is "wss"
  &tcpc:
  ⟜(
    BuildRequest!(
      Url ⊃(⋅⋅∘|⊙∘)
      Method "GET"
      Protocol "HTTP/1.1"
      Header "Upgrade" "websocket"
      Header "Connection" "Upgrade"
      Header "Sec-WebSocket-Key" "dGhlIHNhbXBsZSBub25jZQ=="
      Header "Sec-WebSocket-Protocol" "chat"
      Header "Sec-WebSocket-Version" "13"
    )
    &w FormatHttpRequest
  )
  ⟜(
    ReadHttpResponse
    ParseHttpResponse
    # TODO: handle redirect
    °□get "status"
    $"Invalid status status response from websocket server: _".
    ⍤:=101:
  )
)

Xor ← °⋯≠∩(⬚0↙8⋯)
ApplyMasking ← ∵Xor⊏⊙:◿4⇡⧻.:
ShiftLeft ← °⋯⍥(⊂0):⋯:

ByteArrayToInt ← /+≡ShiftLeft×8⇡⧻.
ReadShort ← ByteArrayToInt ⇌&rb 2
ReadInt ← ByteArrayToInt ⇌&rb 4
ReadLong ← ByteArrayToInt ⇌&rb 8

ReadWebsocketFrame ← (
  ⊙(EmptyWsFrameMetadata)
  ⊙(EmptyWsFrame)
  ⟜(
    ⬚0↙8⋯⊢&rb1
    # Is Final flag
    ⊃(⋅∘|SetWsFrameIsFinal⊙⋅∘) °⊂⇌
    # Opcode
    SetWsFrameOpcode °⋯⇌
  )
  ⟜(
    ⬚0↙8⋯⊢&rb1
    # Is Masked flag
    ⊃(⋅⊙∘|SetWsFrameMetadataIsMasked⊙⋅⋅∘)°⊂⇌
    # Payload length
    ⊃(⋅∘|SetWsFrameMetadataPayloadLength⊙⋅∘)°⋯⇌
  )
  ⟜(
    # Extended payload length
    ⊃(GetWsFrameMetadataPayloadLength⋅⋅∘|⊙⊙∘)
    ⊗:[126 127].
    ⟨ReadShort ◌|ReadLong ◌|⊙◌⟩
    ⊃(⋅∘|SetWsFrameMetadataPayloadLength⊙⋅∘)
  )
  ⟜(
    # Masking Kky
    ⊃(GetWsFrameMetadataIsMasked⋅⋅∘|⊙⊙∘)
    SetWsFrameMaskingKey ⟨0|&rb4⟩
  )

  &rb ⊃(GetWsFrameMetadataPayloadLength⋅⋅∘|⊙⊙∘)
  ⊃(GetWsFrameMetadataIsMasked⋅⋅∘|⊙⊙∘)
  SetWsFramePayload ⍥(ApplyMasking ⊃(GetWsFrameMaskingKey ⋅∘|⊙∘))
  ⊙◌
)

WebsocketFrameToBytes ← (
  :[]
  # First byte (fin, opcode)
  ⟜(⬚0↙7 ⋯GetWsFrameOpcode)
  ⟜(⊂:GetWsFrameIsFinal)
  ⊙(⊂:°⋯)

  # Second byte (masked, payload length)
  ⟜(⬚0↙7 ⋯⧻ GetWsFramePayload)
  ⟜(⊂:¬≍0GetWsFrameMaskingKey)
  ⊙(⊂:°⋯)

  # TODO: Extended payload length

  # Masking key
  ⟜(
    ¬≍0GetWsFrameMaskingKey.
    ⟨◌|⊂:GetWsFrameMaskingKey⟩
  )

  # Payload
  ¬≍0GetWsFrameMaskingKey.
  ⊂: ⟨GetWsFramePayload|ApplyMasking ⊃(GetWsFrameMaskingKey|GetWsFramePayload)⟩
)

SendWebsocketFrame ← &w WebsocketFrameToBytes

EventTypePong ← 0
EventTypeSendFrame ← 1
Struct!(WebsocketEvent|Type|Data)

MessageTypeText ← 0
MessageTypeBinary ← 1
Struct!(WebsocketMessage|Type|Data)

ChannelHandleMessage ← 0
ChannelHandleWrite ← 1
Struct!(ThreadMessage|Channel|Data)

ReadSocketThread ← (
  # socket, handle thread
  ⍢(
    ⟜(
      ReadWebsocketFrame
      # ⟜(&p $"Received frame: _")
      GetWsFrameOpcode.
      ⊗:[OpcodeText OpcodeBinary OpcodePing]
      ⟨
        &p $"Received text frame"
        send 0 BuildThreadMessage!(
          SetThreadMessageChannel ChannelHandleMessage
          SetThreadMessageData BuildWebsocketMessage!(
            SetWebsocketEventType MessageTypeText
            SetWebsocketEventData ⊃(°utf GetWsFramePayload⋅⋅∘|⊙∘)
          )
        )
        | &p $"Received binary frame"
        send 0 BuildThreadMessage!(
          SetThreadMessageChannel ChannelHandleMessage
          SetThreadMessageData BuildWebsocketMessage!(
            SetWebsocketEventType MessageTypeText
            SetWebsocketEventData ⊃(GetWsFramePayload⋅⋅∘|⊙∘)
          )
        )
        | &p $"Received ping, sending pong"
        send 0 BuildThreadMessage!(
          SetThreadMessageChannel ChannelHandleWrite
          SetThreadMessageData BuildWebsocketEvent!(
            SetWebsocketEventType EventTypePong
            SetWebsocketEventData ⊃(GetWsFramePayload⋅⋅∘|⊙∘)
          )
        )
        | ⍤ "Unhandled frame type" 0
      ⟩
    )
  )(1)
)

WriteSocketThread ← (
  ⍢(
    ⟜(
      recv 0
      GetWebsocketEventType.
      ⊗:[EventTypePong EventTypeSendFrame]
      ⟨
        SendWebsocketFrame BuildMaskedWsFrame!(
          SetWsFrameOpcode OpcodePong
          SetWsFramePayload GetWebsocketEventData:
        )
        | SendWebsocketFrame GetWebsocketEventData
      ⟩
    )
  )1
)

ConnectToWebsocket‼ ← (
  CreateWebsocketConnection
  ⟜($recvFrameThread spawn(WriteSocketThread))
  $sendFrameThread spawn(ReadSocketThread)
  $recvHandleThread spawn(^!)
  $websocketEventTread spawn(^!)
  ⊃([⊙⋅∘]|[⋅⊙⋅∘])
  ⍢(
    ⟜(
      ▽≡(¬≍□0).≡(□⍣(tryrecv|0)).
      ⊃(∘|¤⋅⋅∘|⋅⊙∘)
      ◌⍚(send ⊡⊙:°{⊙∘})
    )
  )1
)

SendText ← (
  send 0 BuildThreadMessage!(
    SetThreadMessageChannel ChannelHandleWrite
    SetThreadMessageData BuildWebsocketEvent!(
      SetWebsocketEventType EventTypeSendFrame
      SetWebsocketEventData BuildMaskedWsFrame!(
        SetWsFrameOpcode OpcodeText
        SetWsFramePayload ⊃(utf⋅⋅⋅∘|⊙⊙∘)
      )
    )
  )
)
