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
    { host : String
    , renderedText : a
    , documentIdString : String
    , counter : Int
    , message : String }


type Msg
    = NoOp
    | GetDocument  
    | InputDocumentId String
    | ReceiveDocument (Result Http.Error DocumentRecord)


type alias Flags =
    { host : String, documentId : Int }

initialText = "This is a test: $$\\int_0^1 x^n dx = \\frac{1}{n+1}$$"

init : Flags -> ( Model (Html msg), Cmd Msg )
init flags =
    ( { 
      host = flags.host
    , renderedText = render 0 initialText
    , documentIdString = ""
    , counter = 0
     , message = "Hello!" }, getDocumentById flags.host flags.documentId )


subscriptions : Model (Html msg) -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model (Html msg) -> ( Model (Html msg), Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        InputDocumentId str ->
          ({model | documentIdString = str}, Cmd.none)
        GetDocument ->
           getDocument model
        ReceiveDocument result ->
            case result of
                Ok documentRecord -> 
                    ( { model | renderedText = render model.counter documentRecord.document.content, counter = model.counter + 1 }, Cmd.none )

                Err err ->
                    ( { model | message = "HTTP Error" }, Cmd.none )





render : Int -> String -> Html msg
render seed     sourceText =
    MiniLatex.renderWithSeed seed "$$ $$" sourceText


view : Model (Html Msg) -> Html Msg
view model =
    div outerStyle
     [  div [style "margin-left" "20px" ] [getDocumentButton 100, inputDocumentId, showMessage model ]
        , div [style "margin-top" "10px"] [display model]
       
      ]

showMessage model = 
  span [style "margin-left" "10px"] []
  -- [text <| String.fromInt model.counter]

getDocumentButton width =
    button ([ onClick GetDocument ] ++ buttonStyle colorBlue width) [ text "Get Document" ]

inputDocumentId  = 
  input [ onInput InputDocumentId] [ ]

display : Model (Html Msg) -> Html Msg
display model =
    div renderedSourceStyle [ model.renderedText ]

-- DOCUMENT

getDocument : Model (Html msg) -> (Model (Html msg), Cmd Msg)
getDocument model =
  case (String.toInt model.documentIdString) of 
    Nothing -> (model, Cmd.none)
    Just id -> (model, getDocumentById model.host id)

getDocumentById : String -> Int -> Cmd Msg
getDocumentById host id =
    Http.send ReceiveDocument <| getDocumentByIdRequest host id 

