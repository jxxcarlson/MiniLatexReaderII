module UrlAppParser exposing (Route(..), toRoute, route, idFromLocation)

import Url exposing (Protocol(..), Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, custom, int, map, oneOf, parse, s, string, top)
import Url.Parser.Query as Query


idFromLocation : String -> Maybe Int
idFromLocation str =
    str
        |> Url.fromString
        |> Maybe.andThen .query
        |> Maybe.map (String.split "=")
        |> Maybe.map (List.drop 1)
        |> Maybe.andThen List.head
        |> Maybe.andThen String.toInt



-- https://ellie-app.com/3bTbc38PH8ma1
-- https://discourse.elm-lang.org/t/fragment-routing/1801


type Route
    = NotFound
    | DocumentIdRef (Maybe String)
    | HomeRef String
    | InternalRef String



-- -- parseDocId : Url -> Route
-- parseDocId url =
--   parse int


route : Parser (Route -> a) a
route =
    oneOf
        [ map HomeRef (s "home" </> string)
        , map DocumentIdRef (s "phone" <?> Query.string "id")
        , map InternalRef internalRef
        ]



-- /phone/?id=44    ==>  Just (Overview (Just "44"))


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
