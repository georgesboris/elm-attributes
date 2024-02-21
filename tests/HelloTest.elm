module HelloTest exposing (suite)

import Expect exposing (equal)
import Hello
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Hello.hello"
        [ test "Returns the string 'Hello!'" <|
            \_ ->
                equal Hello.hello "Hello!"
        ]
