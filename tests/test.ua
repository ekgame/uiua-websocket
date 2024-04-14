# Experimental!

~ "../lib.ua"
  ~ BuildWsFrame! SetWsFrameMaskingKey SetWsFrameOpcode SetWsFramePayload
  ~ ReadWebsocketFrame WebsocketFrameToBytes

⍜(&fo "./tests/test-frame-short-unmasked.bin")(
  ReadWebsocketFrame
  BuildWsFrame!(
    SetWsFrameOpcode 1
    SetWsFramePayload utf"Hello"
  )
  ⍤ "Failed to parse frame." ≍
)

⍜(&fo "./tests/test-frame-short-unmasked.bin")(
  &rb ∞
  WebsocketFrameToBytes BuildWsFrame!(
    SetWsFrameOpcode 1
    SetWsFramePayload utf"Hello"
  )
  ⍤ "Failed to encode frame." ≍
)

⍜(&fo "./tests/test-frame-short-masked.bin")(
  ReadWebsocketFrame
  BuildWsFrame!(
    SetWsFrameOpcode 1
    SetWsFrameMaskingKey [55 250 33 61]
    SetWsFramePayload utf"Hello"
  )
  ⍤ "Failed to parse frame." ≍
)

⍜(&fo "./tests/test-frame-short-masked.bin")(
  &rb ∞
  WebsocketFrameToBytes BuildWsFrame!(
    SetWsFrameOpcode 1
    SetWsFrameMaskingKey [55 250 33 61]
    SetWsFramePayload utf"Hello"
  )
  ⍤ "Failed to encode frame." ≍
)
