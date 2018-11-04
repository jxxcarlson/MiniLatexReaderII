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
import TOCParser exposing(TOCElement, tocFromString, titleOfTOCElement, idOfTOCElement, levelOfTOCElement)


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
    , maybeLastDocument : Maybe Document
    , maybeMasterDocument : Maybe Document
    , maybeTexMacroDocument : Maybe Document
    , maybeTexMacroId : Maybe Int
    , counter : Int
    , message : String
    , width : String 
    , height : String 
    , leftmargin : String }


type Msg
    = NoOp
    | GetDocument 
    | GetDocumentById Int 
    | InputDocumentId String
    | ReceiveDocument (Result Http.Error DocumentRecord)
    | ReceiveTexDocument (Result Http.Error DocumentRecord)
    | ToggleMaster   


type alias Flags =
    { host : String
    , documentId : Int
    , width : String
    , height : String 
    , leftmargin : String }

initialText = "This is a test: $$\\int_0^1 x^n dx = \\frac{1}{n+1}$$"

init : Flags -> ( Model (Html msg), Cmd Msg )
init flags =
    (  
        { 
            host = flags.host
            , maybeCurrentDocument = Nothing
            , maybeLastDocument = Nothing
            , maybeTexMacroDocument = Nothing
            , maybeMasterDocument = Nothing
            , maybeTexMacroId = Nothing
            , renderedText = render Nothing 0 initialText
            , documentIdString = ""
            , counter = 0
            , message = "Hello!" 
            , width = flags.width 
            , height = flags.height 
            , leftmargin = flags.leftmargin
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
        GetDocumentById id ->
           (model, getDocumentById model.host id)
        ReceiveDocument result ->
            case result of
                Ok documentRecord -> 
                  let  
                    maybeCurrentDocument = Just documentRecord.document
                    maybeDocumentType = docType maybeCurrentDocument
                    maybeTexMacroId = texMacroId maybeCurrentDocument
                    maybeMasterDocument = case (maybeDocumentType, model.maybeMasterDocument) of 
                      (Just Master, _) -> maybeCurrentDocument
                      (_, Just _) -> model.maybeMasterDocument
                      (_, _) -> Nothing
                    maybeLastDocument = case (maybeDocumentType, model.maybeLastDocument) of 
                      (Just Standard, _) ->  maybeCurrentDocument
                      (_, _) -> model.maybeLastDocument
                    renderedText = case maybeDocumentType of 
                      Just Master -> model.renderedText 
                      Just Standard -> render model.maybeTexMacroDocument  model.counter documentRecord.document.content
                      Nothing -> model.renderedText 
                  in 
                    ( { model | 
                            maybeCurrentDocument = maybeCurrentDocument
                          , maybeTexMacroId = maybeTexMacroId
                          , maybeMasterDocument = maybeMasterDocument
                          , maybeLastDocument = maybeLastDocument
                          , renderedText = renderedText
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


        ToggleMaster ->
          case docType model.maybeCurrentDocument of 
            Just Standard -> ({model | maybeCurrentDocument = model.maybeMasterDocument}, Cmd.none)
            Just Master -> ({model | maybeCurrentDocument = model.maybeLastDocument}, Cmd.none)
            Nothing -> (model, Cmd.none)


view : Model (Html Msg) -> Html Msg
view model =
    div outerStyle
     [  div [ ] [getDocumentButton 120, inputDocumentId model, toggleMasterButton model 120 ]
        , div [ style "margin-top" "10px" ] [titleElement model, authorElement model ]
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
        Master -> displayMasterDocument model document

displayStandardDocument : Model (Html Msg) -> Html Msg
displayStandardDocument model =
    div (renderedSourceStyle model.width model.height) [ model.renderedText ]

displayMasterDocumentAsText : Model (Html Msg) -> Document -> Html Msg
displayMasterDocumentAsText model document =
  let 
    tableOfContents= tocFromString document.content 
    tocInfo = "-----------------------\n" ++ (String.fromInt (List.length tableOfContents)) ++ " documents"
  in
    div (masterDocumentStyle model.width model.height) [ text <| document.content ++ tocInfo]

displayMasterDocument : Model (Html Msg) -> Document -> Html Msg
displayMasterDocument model document =
  div (tocStyle model.width model.height) (toc document)

linkFromTocElement : TOCElement -> Html Msg 
linkFromTocElement tocElement = 
  div [] [
    button ([ onClick <| GetDocumentById (idOfTOCElement tocElement) ] ++ linkStyle colorBlue 300) [ text <| titleOfTOCElement tocElement ]
  ]

toc : Document -> List (Html Msg)
toc document = 
 List.map linkFromTocElement (tocFromString document.content)
    

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
    Standard -> "S"
    Master -> "M"

lastDocTitleElement : Model (Html Msg) -> Html Msg 
lastDocTitleElement model = 
  case model.maybeLastDocument of 
    Nothing -> span [style "margin-right" "10px"] [text <| ""]
    Just document -> span textElementStyle [text <| (String.left 10 document.title) ]


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

texMacroStatus : Model (Html msg) -> String 
texMacroStatus model = 
  case model.maybeTexMacroDocument of 
    Nothing -> "Macros: not loaded"
    Just document -> "Macros: LOADED"

texMacroStatusElement : Model (Html Msg) -> Html Msg 
texMacroStatusElement model = 
  case model.maybeCurrentDocument of 
    Nothing -> span [style "margin-right" "10px"] [text <| ""]
    Just document -> span textElementStyle [text <| texMacroStatus model ]


docType : Maybe Document -> Maybe DocType  
docType maybeDocument = 
  maybeDocument 
    |> Maybe.map .docType
 
    
   

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

toggleMasterButton model width =
  case (model.maybeMasterDocument, model.maybeLastDocument) of 
    (Just _, Just _) -> button ([ onClick ToggleMaster ] ++ buttonStyle colorBlue width ++ [style "margin-left" "10px"]) [ text <| toggleTitle model]
    (_, _) -> span [] []

toggleTitle : Model (Html msg) -> String
toggleTitle model = 
  case docType model.maybeCurrentDocument of 
    Just Master -> "Last document"
    Just Standard -> "Table of contents"
    Nothing -> ""

inputDocumentId  model =  
  input [ onInput InputDocumentId, style "width" "40px", style "height" "18px", HA.placeholder (documentIdString model)] [ ]

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

   