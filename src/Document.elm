module Document exposing(getDocumentByIdRequest, DocumentRecord, Document, texMacroDocumentID)

import Http
import Json.Decode as Decode exposing (Decoder, at, decodeString, int, list, string)
import Json.Decode.Pipeline as JPipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode
import Dict exposing(Dict)
import Time exposing (Posix)
import Parser exposing(Parser, run, succeed, int, symbol, spaces, (|.), (|=))


-- backend : String
-- backend = "https://nshost.herokuapp.com"
-- -- backend = "http://localhost:4000"

timeout : Float 
timeout = 20000



type alias DocumentRecord =
    { document : Document }


type alias Document =   
    { id : Int
    , authorName : String
    , title : String
    , content : String
    , tags : List String
    , docType : DocType
    }

type DocType
    = Standard
    | Master


texMacroDocumentID : List String -> Maybe Int 
texMacroDocumentID tagList = 
  let 
    item = List.filter (String.contains "texmacros:") tagList |> List.head
  in    
    item |> Maybe.andThen (getIntegerValueForKey "texmacros")

getIntegerValueForKey : String -> String -> Maybe Int    
getIntegerValueForKey key str = 
  case run (parseIntegerValueForKey key) str of 
    Ok value -> Just value
    _ -> Nothing 

parseIntegerValueForKey : String -> Parser Int 
parseIntegerValueForKey key = 
  succeed identity 
    |. symbol (key ++ ":")
    |. spaces
    |= int 

getDocumentByIdRequest : String -> Int -> Http.Request DocumentRecord
getDocumentByIdRequest host id  =
    let
      route = "/api/public/documents/" ++ String.fromInt id
      headers = [ Http.header "APIVersion" "V2" ]
    in
    Http.request
        { method = "Get"
        , headers = headers
        , url = host ++ route
        , body = Http.jsonBody Encode.null
        , expect = Http.expectJson documentRecordDecoder
        , timeout = Just timeout
        , withCredentials = False
        }

documentRecordDecoder : Decoder DocumentRecord
documentRecordDecoder =
    Decode.succeed DocumentRecord
        |> JPipeline.required "document" documentDecoder


documentDecoder : Decoder Document
documentDecoder =
    Decode.succeed Document
        |> JPipeline.required "id" Decode.int
        |> JPipeline.required "authorName" Decode.string
        |> JPipeline.required "title" Decode.string
        |> JPipeline.required "content" Decode.string
        |> JPipeline.required "tags" (Decode.list Decode.string)
        |> JPipeline.required "docType" (Decode.string |> Decode.andThen decodeDocType)


decodeDocType : String -> Decoder DocType
decodeDocType docTypeString =
    case docTypeString of
        "standard" ->
            Decode.succeed Standard

        "master" ->
            Decode.succeed Master

        _ ->
            Decode.fail <| "I don't know a docType named " ++ docTypeString
