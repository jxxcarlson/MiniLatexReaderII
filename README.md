# MiniLatex Reader II

MiniLatex Reader II is a small app which can be
embedded in a web page and used to display
LaTeX as HTML. Please see https://knode.io/reader/
for a demonstration. Or try the phone version at
https://knode.io/phone/

Note the trailing slash.

## Using MiniLatex Reader II

1. Clone this repository.

2. To function properly, `index.html` must be provided by a
   web server. You can do this using the inclded file,
   `server.py`. Just say `python server.py`. It should be running on port 8081 --
   the host app is configured to allow requests on this port.

3) Test the app by clicking on `index.html`. It should open in your browswer and
   display the LaTeX content.

4) If you wish, copy the files `index.html` and `Main.min.js` to your webserver
   and configure the start up document id by ediing

## Customizing the app.

Change the line `documentId: 427` to change the start-up document.
Change the phrase `host: "https://nshost.herokuapp.com` to change
the host.

## Reqeust Format

The backend server is the one used by `knode.io`.
The proper form for a request to the backend server
at `nshost.herokuapp.io` is
`https://nshost.herokuapp.io/api/api/public/documents/ID`, where
`ID` is an integer document ID with header `"APIVersion" : "V2"`.

## Document structure

Documents conform to the following type definitons.
See the JSON decoders in `Document.elm` for more details.

```
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
```
