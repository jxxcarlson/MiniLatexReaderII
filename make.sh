color=`tput setaf 48`
reset=`tput setaf 7`

echo
echo "${color}Compiling ...${reset}"
elm make --optimize src/Main.elm --output=Main.js

echo "${color}Minifiying ...${reset}"
uglifyjs Main.js -mc 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9"' -o Main.min.js
