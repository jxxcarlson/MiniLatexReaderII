module UrlAppParser exposing (Route(..), toRoute)

import Url exposing (Protocol(..), Url)
import Url.Parser as Parser exposing ((</>), Parser, custom, int, map, oneOf, parse, s, string, top)


-- https://ellie-app.com/3bTbc38PH8ma1
-- https://discourse.elm-lang.org/t/fragment-routing/1801


type Route
    = NotFound
    | DocumentIdRef Int
    | HomeRef String
    | InternalRef String



-- -- parseDocId : Url -> Route
-- parseDocId url =
--   parse int


route : Parser (Route -> a) a
route =
    oneOf
        [ map HomeRef (s "home" </> string)
        , map DocumentIdRef int
        , map InternalRef internalRef
        ]


internalRef : Parser (String -> a) a
internalRef =
    custom "INNER" <|
        \segment ->
            if String.startsWith "#_" segment then
                Just segment
            else
                Nothing


toRoute : String -> Route
toRoute string =
    case Url.fromString string of
        Nothing ->
            NotFound

        Just url ->
            Maybe.withDefault NotFound (parse route url)


defaultUrl =
    { fragment = Nothing, host = "foo.io", path = "/", port_ = Nothing, protocol = Http, query = Nothing }


testUrlString =
    "http://foo.io/444"


testUrl =
    Url.fromString testUrlString |> Maybe.withDefault defaultUrl
