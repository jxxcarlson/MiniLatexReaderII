module Style exposing(..)

import Html exposing (..)
import Html.Attributes as HA exposing (..)


outerStyle =
    [ style "margin-top" "-25px"
    , style "background-color" "#e1e6e8"
    ]


renderedSourceStyle width height =
    textStyle width height "#fff"

tocStyle width height=
    textStyle width height "#fff"
    
masterDocumentStyle width height=
    textStyle width height "#fff" ++ [style "white-space" "pre"]

textStyle width height color =
    [ style "width" width
    , style "height" height
    , style "padding" "15px"
    , style "background-color" color
    , style "overflow" "scroll"
    , style "float" "left"
    , id "renderedtext"
    ]


labelStyle =
    [ style "margin-top" "5px"
    , style "margin-bottom" "0px"
    , style "margin-left" "20px"
    , style "font-weight" "bold"
    ]




colorBlue =
    "rgb(100,100,200)"


colorLight =
    "#88a"


colorDark =
    "#444"


buttonStyle : String -> Int -> List (Html.Attribute msg)
buttonStyle color width =
    let
        realWidth =
            width + 0 |> String.fromInt |> (\x -> x ++ "px")
    in
    [ style "backgroundColor" color
    , style "color" "white"
    , style "width" realWidth
    , style "height" "25px"
    , style "margin-top" "20px"
    , style "margin-right" "12px"
    , style "font-size" "9pt"
    , style "text-align" "center"
    , style "border" "none"
    ]

linkStyle : String -> Int -> List (Html.Attribute msg)
linkStyle color width =
    let
        realWidth =
            width + 0 |> String.fromInt |> (\x -> x ++ "px")
    in
    [ style "color" colorBlue
    , style "width" realWidth
    , style "height" "25px"
    , style "font-size" "9pt"
    , style "text-align" "left"
    , style "border" "none"
    , style "background-color" "#fff"
    ]

