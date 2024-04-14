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
BuildWsFrame! ← ^! SetWsFrameIsFinal 1 EmptyWsFrame
BuildMaskedWsFrame! ← ^! SetWsFrameIsFinal 1 EmptyWsFrame

FormatAddress ← $"_:_" ∩°□⊃(get "domain")(get "port")
StreamReadLine ← ↘¯2◌:⍢(⊂:⊙:&rs1.:)(¬≍ "\r\n" ⬚@ ↙¯2)""
ReadHttpResponse ← ◌:⍢(⊂:"\r\n"⊂:⊙:StreamReadLine.:)(¬≍ "\r\n\r\n" ⬚@ ↙¯4)""

CreateWebsocketConnection ← (
  Uri~Parse
  ⟜FormatAddress
  get"schema".
  ⊗:{"ws" "wss"}.
  ⟨"http"◌|"https"◌|0⍤:0 $"invalid schema: _"⟩
  insert "schema"
  Uri~Build

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

SendFrame ← &w WebsocketFrameToBytes
