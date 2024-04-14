# Experimental!

~ "git: github.com/ekgame/uiua-http"
  ~ Body Header Method Protocol Url
  ~ BuildRequest! FormatHttpRequest ParseHttpResponse

Uri ~ "git: github.com/ekgame/uiua-uri-parser"

OpcodeContinuation ← 0
OpcodeText ← 1
OpcodeBinary ← 2
OpcodeClose ← 8
OpcodePing ← 9
OpcodePong ← 10

Struct! ↚^ (
  ◇⟜(⍚⊂¤)°⊂
  □$"_ ← {_}\n":⊂⊃(↯:@⊙-1|↯:@∘±)⧻,
  ⍚$"_ ← °□⊡_\n":⇡⧻.:
  ⊂:
)
Struct!(WsFrame|IsFinalFragment|Opcode|IsMasked|PayloadLength|MaskingKey|Payload)

DefaultFrame ← (WsFrame 1 OpcodeText 0 0 0 [])
BuildFrame! ← ^! DefaultFrame

RandomByte ← (⌊×256⚂)
DefaultMaskedFrame ← (WsFrame 1 OpcodeText 1 0 [⍥RandomByte 4] [])
BuildMaskedFrame! ← ^! DefaultMaskedFrame

Opcode ← ⍜(WsFrameOpcode)(◌):
MaskingKey ← ⍜(WsFrameMaskingKey)(◌):
Payload ← (
  ⍜(WsFramePayload)(◌):⊙:.
  ⍜(WsFramePayloadLength)(◌):⧻:
)

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
ApplyMask ← ∵Xor⊏⊙:◿4⇡⧻.:
ShiftLeft ← °⋯⍥(⊂0):⋯:

ByteArrayToInt ← /+≡ShiftLeft×8⇡⧻.
ReadShort ← ByteArrayToInt ⇌&rb 2
ReadInt ← ByteArrayToInt ⇌&rb 4
ReadLong ← ByteArrayToInt ⇌&rb 8

ReadWebsocketFrame ← (
  :{}
  ⟜(
    ⬚0↙8⋯ ⊢&rb 1
    # Is Final flag
    :⊂:□⊙: °⊂⇌
    # Opcode
    ⊂:□°⋯⇌
  )
  ⟜(
    ⬚0↙8⋯ ⊢&rb 1
    # Is Masked flag
    :⊂:□⊙: °⊂⇌
    # Payload length
    ⊂:□°⋯⇌
  )
  ⟜(
    # Extended payload length
    :⊙(WsFramePayloadLength.)
    ⊗:[126 127].
    ⟨ReadShort ◌|ReadLong ◌|⊙◌⟩
    ⍜⊙(WsFramePayloadLength)(◌)
  )
  ⟜(
    # Mask key
    ⊙:WsFrameIsMasked.:
    ⊂:⟨0|□&rb4⟩
  )
  # Payload
  &rb ⊙:WsFramePayloadLength.:
  # Unmask payload
  ⊙:WsFrameIsMasked.:
  ⊂:□⍥(ApplyMask WsFrameMaskingKey:⊙.)
)

WebsocketFrameToBytes ← (
  :[]
  # First byte (fin, opcode)
  ⟜(⬚0↙7 ⋯WsFrameOpcode)
  ⟜(⊂:WsFrameIsFinalFragment)
  ⊙(⊂:°⋯)

  # Second byte (masked, payload length)
  ⟜(⬚0↙7 ⋯WsFramePayloadLength)
  ⟜(⊂:WsFrameIsMasked)
  ⊙(⊂:°⋯)

  # TODO: Extended payload length

  # Masking key
  ⟜(
    WsFrameIsMasked.
    ⟨◌|⊂:WsFrameMaskingKey⟩
  )

  # Payload
  WsFrameIsMasked.
  ⊂: ⟨WsFramePayload|ApplyMask ⊃(WsFrameMaskingKey|WsFramePayload)⟩
)

SendFrame ← &w WebsocketFrameToBytes
