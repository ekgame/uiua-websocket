# Experimental!

~ "../lib.ua"
  ~ BuildFrame! BuildMaskedFrame! MaskingKey Opcode Payload
  ~ ReadWebsocketFrame WebsocketFrameToBytes

⍜(&fo "./tests/test-frame-short-unmasked.bin")(
  ReadWebsocketFrame
  BuildFrame!(
    Opcode 1
    Payload utf"Hello"
  )
  ⍤ "Failed to parse frame." ≍
)

⍜(&fo "./tests/test-frame-short-unmasked.bin")(
  &rb ∞
  WebsocketFrameToBytes BuildFrame!(
    Opcode 1
    Payload utf"Hello"
  )
  ⍤ "Failed to encode frame." ≍
)

⍜(&fo "./tests/test-frame-short-masked.bin")(
  ReadWebsocketFrame
  BuildMaskedFrame!(
    Opcode 1
    MaskingKey [55 250 33 61]
    Payload utf"Hello"
  )
  ⍤ "Failed to parse frame." ≍
)

⍜(&fo "./tests/test-frame-short-masked.bin")(
  &rb ∞
  WebsocketFrameToBytes BuildMaskedFrame!(
    Opcode 1
    MaskingKey [55 250 33 61]
    Payload utf"Hello"
  )
  ⍤ "Failed to encode frame." ≍
)
