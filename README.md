# MiniLatex Reader

MiniLatex Reader is a small app which can be
embedded in a web page and used to display
LaTeX as HTML. Please see
[MiniLatex Reader](https://jxxcarlson.github.io/app/miniLatexReader/index.html)
for a demonstration.

## Using MiniLatex Reader

1. Clone this repository.

2. Replace the contents of `<div id="source" style="display:none"> ... </div>`
   in `index.html` with your own content. Make sure that your editor does not indent the text.

3. Test the app by clicking on `index.html`.  It should open in your browswer and
   display the LaTeX content.

4. Copy the files `index.html` and `Main.min.js` to your webserver.

**Note.** I've moved the app to MathJax 3.0, which is still in beta.  If you
want use MathJax 2.7, use `index-old.html`.  If you use MathJax 3.0, you will
also have to copy the file `mj3-tex2html-simple.dist.js`.  There will no
doubt be some changes to `index.html` once I understand MathJax 3.0. better.


## Customizing the app.

If you make changes to `index.html`, there is nothing further to do.
If you make changes to `src/Main.elm`, run the script `make.sh`:

```
   $ sh make.sh
```
