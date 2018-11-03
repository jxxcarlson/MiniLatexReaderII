# MiniLatex Reader II

MiniLatex Reader iII s a small app which can be
embedded in a web page and used to display
LaTeX as HTML. Please see
[MiniLatex Reader II](https://knode.io/reader)
for a demonstration.

## Using MiniLatex Reader II

1. Clone this repository.

2. Use the included file, `server.py` to run a small web server by
   saying `python server.py`. It should be running on port 8081 --
   the host app is configured to allow requests on this port.

3) Test the app by clicking on `index.html`. It should open in your browswer and
   display the LaTeX content.

4) If you wish, copy the files `index.html` and `Main.min.js` to your webserver
   and configure the start up document id by ediing

## Customizing the app.

Change the line `documentId: 427` to change the start-up document.
Change the phrase `host: "https://nshost.herokuapp.com` to change
the host.
