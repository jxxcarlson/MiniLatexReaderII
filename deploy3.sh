color=`tput setaf 48`
magenta=`tput setaf 5`
reset=`tput setaf 7`

HOST="root@138.197.81.6"
READER3="/var/www/html/reader3/"
PHONE="/var/www/html/phone/"
DIST_LOCAL="./dist/"


# https://guide.elm-lang.org/optimization/asset_size.html

echo

time elm make --optimize ./src/Main.elm --output Main.js

echo "${color}Uglify and deploy to Digital Ocean${reset}"
time uglifyjs ${NGINX_LOCAL}Main.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=${NGINX_LOCAL}Main.min.js

scp -r Main.min.js ${HOST}:${READER3}Main.min.js
scp -r index2.html ${HOST}:${READER3}index.html

echo "${color}Done!${reset}"




