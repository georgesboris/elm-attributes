module Attr exposing
    ( attr, withAttrs, toAttrs, Attr
    , if_, maybe, batch, filter, none
    )

{-|


# Creating attribute based APIs

In this example, we will create a button module using the opaque attribute pattern.

    module Button exposing
        ( Attribute
        , background
        , color
        , disabled
        , view
        )

.

    import Html as H exposing (Html)
    import Html.Attributes as HA
    import Html.Events as HE

First, lets define the attributes we will want to use for constructing our module.

    type alias Attributes =
        { color : String
        , background : String
        , disabled : Bool
        }

    type alias Attribute =
        Attr.Attr Attributes

    defaultAttrs : Attributes
    defaultAttrs =
        { color = "white"
        , background = "black"
        , disabled = False
        }

**Important**

  - You **need to use a `type alias`** for the attributes record.
  - You **should not expose this `type alias`**.

This way you will protect the API from constant breaking changes when we change the attributes record internally.

Then, we can create functions that will be used to pass in attributes to our module.

    color : String -> Attribute
    color value =
        Attr.attr (\attrs -> { attrs | color = value })

    background : String -> Attribute
    background value =
        Attr.attr (\attrs -> { attrs | background = value })

    disabled : Attribute
    disabled =
        Attr.attr (\attrs -> { attrs | disabled = True })

Finally, lets create the view function that builds our final result.

In this example we're using a pattern where all optional settings are passed as attributes, and as a second argument we receive a record with required arguments.

    view : List Attribute -> { label : String, onClick : msg } -> Html msg
    view =
        Attr.withAttrs defaultAttrs
            (\attrs props ->
                H.button
                    [ HA.style "color" attrs.color
                    , HA.style "background" attrs.background
                    , HA.disabled attrs.disabled
                    , HE.onClick props.onClick
                    ]
                    [ H.text props.label ]
            )

You can also manually fold all your attributes into the attributes record manually.

This is what the same function above would look like using this approach:

    view : List Attribute -> { label : String, onClick : msg } -> Html msg
    view attrList props =
        let
            attrs : Attributes
            attrs =
                Attr.toAttrs defaultAttrs attrList
        in
        H.button
            [ HA.style "color" attrs.color
            , HA.style "background" attrs.background
            , HA.disabled attrs.disabled
            , HE.onClick props.onClick
            ]
            [ H.text props.label ]

@docs attr, withAttrs, toAttrs, Attr


# Using opaque attribute based APIs

The opaque attribute API is similar to familiar libraries like `elm/html`, `rtfeldman/elm-css` and `terezka/elm-charts`.
The learning curve is very low, so not a lot of explanation is needed.

Here we're using the module defined above to create a button.

    import Button
    import Html as H exposing (Html)

    button : Html msg
    button =
        Button.view
            [ Button.background "green" ]
            { label = "Submit"
            , onClick = ClickedSubmit
            }


# Common Utilities

We provide a few utility functions that are commonly useful for opaque attribute APIs.

This is needed due to the opaqueness of the type. Otherwise, the API author would need to implement similar functions for each module.

@docs if_, maybe, batch, filter, none

-}

-- Builders


{-| -}
type Attr attrs
    = Attr (attrs -> attrs)
    | AttrBatch (List (Attr attrs))


{-| -}
attr : (attrs -> attrs) -> Attr attrs
attr =
    Attr


{-| -}
toAttrs : attrs -> List (Attr attrs) -> attrs
toAttrs =
    List.foldl
        (\attr_ acc ->
            case attr_ of
                Attr fn ->
                    fn acc

                AttrBatch fns ->
                    toAttrs acc fns
        )


{-| -}
withAttrs : attrs -> (attrs -> a) -> List (Attr attrs) -> a
withAttrs attrs fn attrList =
    fn (toAttrs attrs attrList)



-- Helpers


{-|

    button : Bool -> Html msg
    button disabled =
        Button.view
            [ Attr.if_ disabled Button.disabled ]
            { label = "Submit"
            , onClick = ClickedSubmit
            }

-}
if_ : Bool -> Attr attrs -> Attr attrs
if_ predicate attr_ =
    if predicate then
        attr_

    else
        none


{-| Conditionally apply attributes based on `Maybe a` values.

    button : Maybe String -> Html msg
    button customColor =
        Button.view
            [ Attr.maybe Button.color customColor
            ]
            { label = "Submit"
            , onClick = Submitted
            }

-}
maybe : (a -> Attr attrs) -> Maybe a -> Attr attrs
maybe toAttr maybeA =
    maybeA
        |> Maybe.map toAttr
        |> Maybe.withDefault none


{-| Apply multiple attributes at the same time.

    primaryAttrs : Button.Attribute
    primaryAttrs =
        Attr.batch
            [ Button.color "black"
            , Button.background "lime"
            ]

    secondaryAttrs : Button.Attribute
    secondaryAttrs =
        Attr.batch
            [ Button.color "white"
            , Button.background "blue"
            ]

    button : Bool -> Html msg
    button isPrimary =
        Button.view
            [ if isPrimary then
                primaryAttrs

              else
                secondaryAttrs
            ]
            { label = "Submit"
            , onClick = Submitted
            }

-}
batch : List (Attr attrs) -> Attr attrs
batch =
    AttrBatch


{-| Conditionally apply attributes, similar to `classList`.

    Button.view
        [ Attr.filter
            [ ( primaryAttrs, isPrimary )
            , ( secondaryAttrs, not isPrimary )
            , ( Button.disabled, isDisabled )
            ]
        ]
        { label = "Submit"
        , onClick = Submitted
        }

-}
filter : List ( Attr attrs, Bool ) -> Attr attrs
filter attrList =
    attrList
        |> List.filterMap
            (\( attr_, predicate ) ->
                if predicate then
                    Just attr_

                else
                    Nothing
            )
        |> AttrBatch


{-| A noop attribute. Useful for conditionally passing an attribute to a list, instead of relying on list concatenations.

    Button.view
        [ if disabled then
            Button.disabled

          else
            Attr.none
        ]
        { label = "Submit"
        , onClick = Submitted
        }

You can think of it as the equivalent of `text ""` or `class ""`.

-}
none : Attr attrs
none =
    Attr identity
