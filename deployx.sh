color=`tput setaf 48`
reset=`tput setaf 7`

echo
echo "${color}Compiling ...${reset}"
elm make --optimize src/Main.elm --output=Main.js

echo "${color}Minifiying ...${reset}"
uglifyjs Main.js -mc 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9"' -o dist/Main.min.js


echo "${color}Copying to github_pages/app/miniLatexReaderX/${reset}"
cp Main.min.js /Users/carlson/dev/github_pages/app/miniLatexReaderX/
cp index-x1.html /Users/carlson/dev/github_pages/app/miniLatexReaderX/
cp index-x2.html /Users/carlson/dev/github_pages/app/miniLatexReaderX/
cp mj3-tex2html-simple.dist.js /Users/carlson/dev/github_pages/app/miniLatexReaderX/
