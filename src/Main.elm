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
import Document exposing(
      Document
    , DocumentRecord
    , DocType(..)
    , getDocumentByIdRequest
    , texMacroDocumentID
   )
import Style exposing(..)
import TOCParser exposing(..)


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
    , maybeCurrentDocument : Maybe Document
    , maybeTexMacroDocument : Maybe Document
    , maybeTexMacroId : Maybe Int
    , counter : Int
    , message : String }


type Msg
    = NoOp
    | GetDocument  
    | InputDocumentId String
    | ReceiveDocument (Result Http.Error DocumentRecord)
    | ReceiveTexDocument (Result Http.Error DocumentRecord)


type alias Flags =
    { host : String, documentId : Int }

initialText = "This is a test: $$\\int_0^1 x^n dx = \\frac{1}{n+1}$$"

init : Flags -> ( Model (Html msg), Cmd Msg )
init flags =
    (  
        { 
            host = flags.host
            , maybeCurrentDocument = Nothing
            , maybeTexMacroDocument = Nothing
            , maybeTexMacroId = Nothing
            , renderedText = render Nothing 0 initialText
            , documentIdString = ""
            , counter = 0
            , message = "Hello!" 
        }
        , getDocumentById flags.host flags.documentId 
    )


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
                  let  
                    maybeCurrentDocument = Just documentRecord.document
                    maybeTexMacroId = texMacroId maybeCurrentDocument
                  in 
                    ( { model | 
                            maybeCurrentDocument = maybeCurrentDocument
                          , maybeTexMacroId = maybeTexMacroId
                          , renderedText = render model.maybeTexMacroDocument  model.counter documentRecord.document.content
                          , counter = model.counter + 1 
                        }, getTexDocumentById model.host maybeTexMacroId )

                Err err ->
                    ( { model | message = "HTTP Error" }, Cmd.none )
        ReceiveTexDocument result ->
            case result of
                Ok documentRecord ->  
                    ( { model | 
                            maybeTexMacroDocument = Just documentRecord.document
                        }, Cmd.none )

                Err err ->
                    ( { model | message = "HTTP Error" }, Cmd.none )





view : Model (Html Msg) -> Html Msg
view model =
    div outerStyle
     [  div [style "margin-left" "20px" ] [getDocumentButton 100, inputDocumentId model, docTypeElement model]
        , div [style "margin-left" "20px", style "margin-top" "10px" ] [titleElement model, authorElement model ]
        , div [style "margin-top" "10px"] [display model]
       
      ]


--- 
--- MAIN VIEW FUNCTIONS
---

display : Model (Html Msg) -> Html Msg
display model =
  case  model.maybeCurrentDocument of 
    Nothing -> div [] [text "Document not loaded"]
    Just document ->
      case document.docType of 
        Standard -> displayStandardDocument model
        Master -> displayMasterDocument document

displayStandardDocument : Model (Html Msg) -> Html Msg
displayStandardDocument model =
    div renderedSourceStyle [ model.renderedText ]

displayMasterDocument : Document -> Html Msg
displayMasterDocument document =
  let 
    toc = tocFromString document.content 
    tocInfo = "-----------------------\n" ++ (String.fromInt (List.length toc)) ++ " documents"
  in
    div masterDocumentStyle [ text <| document.content ++ tocInfo]



---
--- DOCUMENT RENDERING
---


render : Maybe Document -> Int -> String -> Html msg
render maybeTexDocument seed sourceText =
  let 
    texMacros = case maybeTexDocument of 
      Nothing -> "\\newcommand{\\nothingXXX}{}"
      Just document -> document.content |> normalize  
  in 
    MiniLatex.renderWithSeed seed texMacros sourceText


normalize : String -> String
normalize str =
    str |> String.lines |> List.filter (\x -> x /= "") |> String.join "\n"


--- 
--- VIEW HELPERS
---

firstTextElementStyle = [style "margin-right" "10px", style "margin-left" "10px"]
textElementStyle = [style "margin-right" "10px"]
boldTextlementStyle = [style "margin-right" "10px", style "font-weight" "bold", style "font-size" "18px"]


docTypeElement : Model (Html Msg) -> Html Msg 
docTypeElement model = 
  case model.maybeCurrentDocument of 
    Nothing -> span [style "margin-right" "10px"] [text <| ""]
    Just document -> span firstTextElementStyle [text <| docTypeText document ]

docTypeText : Document -> String 
docTypeText document = 
  case document.docType of 
    Standard -> "Standard document"
    Master -> "Master document"

titleElement : Model (Html Msg) -> Html Msg 
titleElement model = 
  case model.maybeCurrentDocument of 
    Nothing -> span [style "margin-right" "10px"] [text <| ""]
    Just document -> span boldTextlementStyle [text <| document.title ]

authorElement : Model (Html Msg) -> Html Msg 
authorElement model = 
  case model.maybeCurrentDocument of 
    Nothing -> span [style "margin-right" "10px"] [text <| ""]
    Just document -> span textElementStyle [text <| document.authorName ]

texMacroId : Maybe Document -> Maybe Int  
texMacroId maybeDocument = 
  maybeDocument 
    |> Maybe.map .tags
    |> Maybe.andThen texMacroDocumentID

displayTexMacroId : Model (Html msg) -> String 
displayTexMacroId model = 
  case model.maybeTexMacroId of 
    Nothing -> "---"
    Just id -> String.fromInt id

showMessage model = 
  case model.maybeCurrentDocument of  
    Nothing -> span [style "margin-left" "10px"] [] 
    Just document -> span [style "margin-left" "10px"] [text <| displayTexMacroId model]

getDocumentButton width =
    button ([ onClick GetDocument ] ++ buttonStyle colorBlue width) [ text "Get Document" ]

inputDocumentId  model =  
  input [ onInput InputDocumentId, style "width" "40px", HA.placeholder (documentIdString model)] [ ]

documentIdString : Model (Html msg) -> String 
documentIdString model = 
  case model.maybeCurrentDocument of 
    Nothing -> ""
    Just document -> String.fromInt document.id


--
-- DOCUMENT REQUESTS
--

getDocument : Model (Html msg) -> (Model (Html msg), Cmd Msg)
getDocument model =
  case (String.toInt model.documentIdString) of 
    Nothing -> (model, Cmd.none)
    Just id -> (model, getDocumentById model.host id)

getDocumentById : String -> Int -> Cmd Msg
getDocumentById host id =
    Http.send ReceiveDocument <| getDocumentByIdRequest host id 



getTexDocumentById : String -> Maybe Int -> Cmd Msg
getTexDocumentById host maybeId =
  case maybeId of 
    Nothing -> Cmd.none  
    Just id -> Http.send ReceiveTexDocument <| getDocumentByIdRequest host id 

   