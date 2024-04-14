# Experimental!

Struct! ←^ (
  # Parse into a map before processing
  :map {"private"} {0}
  ⟜(⍥(insert"private"1) ≍"Private" °□⊢)
  ⍥(↘1)⊙:°□get"private".:
  insert"args"□:insert"name"⊙:°⊂

  ⊙{}
  # Create builder function
  ⟜(
    ⊃(
      °□get"name"
    | ⊡:["←" "↚"]°□get"private"
    | °□get"name"
    )
    ⊂□$"Build_! _ ^! Empty_"
  )

  # Create empty object function
  ⟜(
    ⊃(
      °□get"name"
    | ⊡:["←" "↚"]°□get"private"
    | /$"_ _"⍚($"$_ 0")°□get"args"
    )
    ⊂□$"Empty_ _ {_}"
  )

  # Create getter functions
  ⟜(
    ⊃(°□get"args"|°□get"private"|get"name")
    :⇡⧻.
    ⊂⍚($"Get__ _ °□⊡ _"⊃(⋅⋅⋅∘|∘|⊡:["←" "↚"]⋅⋅∘|⋅∘))
  )

  # Create setter functions
  ⊃(°□get"args"|°□get"private"|get"name")
  :⇡⧻.
  ⊂⍚($"Set__ _ ⍜(°□⊡⊙:)($_ ◌) _"⊃(⋅⋅⋅∘|∘|⊡:["←" "↚"]⋅⋅∘|∘|⋅∘))
  /$"_\n_"
)
