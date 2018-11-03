module TOCParser exposing(TOCElement, tocFromString, titleOfTOCElement, idOfTOCElement, levelOfTOCElement)

import Parser exposing(..)

type TOCElement = 
  TOCElement Int Int String 

titleOfTOCElement : TOCElement -> String
titleOfTOCElement  (TOCElement level_ id_ title_) =
  title_

idOfTOCElement : TOCElement -> Int
idOfTOCElement  (TOCElement level_ id_ title_)  =
  id_

levelOfTOCElement : TOCElement -> Int
levelOfTOCElement  (TOCElement level_ id_ title_)  =
  level_

tocFromString : String -> List TOCElement
tocFromString str =
  case run tocListParser (normalize str) of 
    Ok tocList -> tocList 
    _ -> []

normalize : String -> String
normalize str =
    str 
    |> String.lines 
    |> List.filter (\line -> line /= "") 
    |> List.filter (\line -> String.startsWith "=" line)
    |> String.join "\n"


tocListParser : Parser (List TOCElement)
tocListParser = 
  many tocElementParser

tocElementParser : Parser TOCElement 
tocElementParser = 
  succeed TOCElement
    |= level
    |. spaces
    |= int 
    |. spaces 
    |= title 
    |. spaces


level : Parser Int 
level = 
  tocPrefix |> map String.length

tocPrefix : Parser String
tocPrefix = 
  getChompedString <|
    succeed ()
      |. chompWhile (\char -> char == '=')



title : Parser String
title =
  getChompedString <|
    succeed ()
      |. chompWhile (\char -> char /= '\n')


{-| Apply a parser zero or more times and return a list of the results.
-}
many : Parser a -> Parser (List a)
many p =
    loop [] (manyHelp p)

manyHelp : Parser a -> List a -> Parser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]
