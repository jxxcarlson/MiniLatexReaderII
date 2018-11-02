module Main exposing (main)

import Browser
import Debounce exposing (Debounce)
import Html exposing (..)
import Html.Attributes as HA exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import Json.Encode
import MiniLatex.Differ exposing (EditRecord)
import MiniLatex.MiniLatex as MiniLatex
import Random
import Task
import Http
import Document exposing(getDocumentByIdRequest, DocumentRecord)
import Style exposing(..)


main : Program Flags (Model (Html Msg)) Msg
main =
    Browser.element
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        }


type alias Model a =
    { renderedText : a
    , message : String }


type Msg
    = NoOp
    | GetDocument  
    | ReceiveDocument (Result Http.Error DocumentRecord)


type alias Flags =
    {  }

initialText = "This is a test: $$\\int_0^1 x^n dx = \\frac{1}{n+1}$$"

init : Flags -> ( Model (Html msg), Cmd Msg )
init flags =
    ( { renderedText = render initialText, message = "Hello!" }, getDocumentById 427 )


subscriptions : Model (Html msg) -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model (Html msg) -> ( Model (Html msg), Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        GetDocument ->
           (model, getDocumentById 423)
        ReceiveDocument result ->
            case result of
                Ok documentRecord -> 
                    ( { model | renderedText = render documentRecord.document.content }, Cmd.none )

                Err err ->
                    ( { model | message = "HTTP Error" }, Cmd.none )



render : String -> Html msg
render sourceText =
    MiniLatex.render "$$ $$" sourceText


view : Model (Html Msg) -> Html Msg
view model =
    div outerStyle
     [  div [style "margin-left" "20px" ] [getDocumentButton 100]
        , div [style "margin-top" "10px"] [display model]
       
      ]

getDocumentButton width =
    button ([ onClick GetDocument ] ++ buttonStyle colorBlue width) [ text "Get Document" ]


display : Model (Html Msg) -> Html Msg
display model =
    div renderedSourceStyle [ model.renderedText ]


renderedSource : Model (Html msg) -> Html msg
renderedSource model =
    Html.div renderedSourceStyle
        [ model.renderedText ]



-- DOCUMENT

getDocumentById : Int -> Cmd Msg
getDocumentById id =
    Http.send ReceiveDocument <| getDocumentByIdRequest id 

