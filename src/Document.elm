module Document exposing(getDocumentByIdRequest, DocumentRecord)

import Http
import Json.Decode as Decode exposing (Decoder, at, decodeString, int, list, string)
import Json.Decode.Pipeline as JPipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode
import Dict exposing(Dict)
import Time exposing (Posix)


backend : String
backend = "https://nshost.herokuapp.com"
-- backend = "http://localhost:4000"

timeout : Float 
timeout = 20000



type alias DocumentRecord =
    { document : Document }


type alias Document =
    { id : Int
    , authorName : String
    , title : String
    , content : String
    }




getDocumentByIdRequest : Int -> Http.Request DocumentRecord
getDocumentByIdRequest id  =
    let
      route = "/api/public/documents/" ++ String.fromInt id
      headers = [ Http.header "APIVersion" "V2" ]
    in
    Http.request
        { method = "Get"
        , headers = headers
        , url = backend ++ route
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