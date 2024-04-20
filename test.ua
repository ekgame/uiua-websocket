# Experimental!

$recvThreadOne spawn(
  ⍢(
    # receive a message from sendThread
    &p $"Two: _" recv 0
  )1
)
$recvThreadZero spawn(
  ⍢(
    # receive a message from sendThread
    &p $"One: _" recv 0
  )1
)
$sendThreadTwo spawn(
  ⍢(
    # send a message to recvThreadOne
    send 0 {0"ping One"}
    &sl 1
    # send a message to recvThreadTwo
    send 0 {1 "pong One"}
    &sl 1
  )1
)
$sendThreadOne spawn(
  ⍢(
    # send a message to recvThreadOne
    send 0 {0 "ping Two"}
    &sl 2
    # send a message to recvThreadTwo
    send 0 {1 "pong Two"}
    &sl 2
  )1
)
# Collect the threads into boxes for convenience
⊃(⊟|[⋅⋅⊙∘])
⍢(
  ⟜(
    ▽≡(¬≍□0).≡(□⍣(tryrecv|0)).
    ⊃(∘|¤⋅⋅∘|⋅⊙∘)
    ◌⍚(send ⊡⊙:°{⊙∘})
  )
)1
