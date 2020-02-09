# shellcheck shell=ksh
# The MIT License (MIT)

# Copyright (c) 2020 -, Rawiri Blundell

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

################################################################################
# Author's note: This is an exercise for my own amusement/education.
# If it works well for you, fantastic!  If you have ideas, please submit them :)
# If you need more power, check out https://github.com/jpmens/jo

# Our variant of die()
json_vorhees() {
  printf -- 'Exception: %s\n' "${@}" >&2
  exit 1
}

# A curly brace to denote the opening of something, usually the json block
json_open() {
  printf -- '%s' "{"
}

# The partner for json_open()
json_close() {
  printf -- '%s' "}"
}

# Sometimes you may need to remove a trailing comma when processing a list
# i.e. the last value, object, array etc
# You should really try to structure your code to not need this
json_decomma() {
  sed 's/\(.*\),/\1 /'
}

# Open an array block
# If an arg is provided, we return '"name": ['
# Without any arg, we simply return '['
json_arr_open() {
  case "${1}" in
    ('')  printf -- '%s' "[" ;;
    (*)   printf -- '"%s": [' "${1}" ;;
  esac
}

# Close an array block
# With '-n' or -'--nocomma', we return ']'
# Without either arg, we return '],'
json_arr_close() {
  case "${1}" in
    (-n|--nocomma) shift 1; _comma="" ;;
    (*)            _comma="," ;;
  esac
  printf -- '%s%s' "]" "${_comma}"
  unset -v _comma
}

# Open an object block
# If an arg is provided, we return '"name": {'
# Without any arg, we simply return '{'
json_obj_open() {
  case "${1}" in
    ('')  printf -- '%s' "{" ;;
    (*)   printf -- '"%s": {' "${1:-null}" ;;
  esac
}

# Close an object block
# With '-n' or -'--nocomma', we return '}'
# Without either arg, we return '},'
json_obj_close() {
  case "${1}" in
    (-n|--nocomma)  json_close ;;
    (*)             printf -- '%s,' "}" ;;
  esac 
}

# A function to escape characters that must be escaped in JSON
# This converts stdin into a single column of octals
# We then search for our undesirable octals and emit our replacements
# Modified from https://stackoverflow.com/a/23166624
# Some of these might not be strictly necessary... YMMV...
json_str_escape() {
  od -A n -t o1 -v | tr ' \t' '\n\n' | grep . | sed '$d' |
    while read -r _char; do
      case "${_char}" in
        ('00[0-7]')  printf -- '\u00%s' "${_char}" ;;
        ('02[0-7]')  printf -- '\u00%s' "$(( _char - 10 ))" ;;
        ('010')  printf -- '%s' "\b" ;;
        ('011')  printf -- '%s' "\t" ;;
        ('012')  printf -- '%s' "\n" ;;
        ('013')  printf -- '\u00%s' "0B" ;;
        ('014')  printf -- '%s' "\f" ;;
        ('015')  printf -- '%s' "\r" ;;
        ('016')  printf -- '\u00%s' "0E" ;;
        ('017')  printf -- '\u00%s' "0F" ;;
        ('030')  printf -- '\u00%s' "18" ;;
        ('031')  printf -- '\u00%s' "19" ;;
        ('042')  printf -- '%s' "\\\"" ;;
        ('047')  printf -- '%s' "\'" ;;
        ('057')  printf -- '%s' "\/" ;;
        ('134')  printf -- '%s' "\\" ;;
        (''|*)   printf -- \\${_char} ;;
      esac
    done
}

# Format a string keypair
# With '-n' or '--nocomma', we return '"key": "value"'
# Without either arg, we return '"key": "value",'
# If the value is blank or literally 'null', we return 'null' unquoted
json_str() {
  case "${1}" in
    (-n|--nocomma) shift 1; _comma="" ;;
    (*)            _comma="," ;;
  esac
  _key="${1:-null}"
  case "${2}" in
    (null|'') printf -- '"%s": %s%s' "${_key}" "null" "${_comma}" ;;
    (*)       shift 1; printf -- '"%s": "%s"%s' "${_key}" "${*}" "${_comma}" ;;
  esac
  unset -v _comma _key
}

# Format a number keypair using signed decimal.  Numbers are unquoted.
# With '-n' or '--nocomma', we return '"key": value'
# Without either arg, we return '"key": value,'
# If the value is not a number, an error will be thrown
# TO-DO: Possibly extend to allow floats and scientific notataion
json_num() {
  case "${1}" in
    (-n|--nocomma) shift 1; _comma="" ;;
    (*)            _comma="," ;;
  esac
  case "${2}" in
    (*[!0-9]*|'') json_vorhees "Value not a number" ;;
  esac
  printf -- '"%s": %d%s' "${1:-null}" "${2:-null}" "${_comma}"
  unset -v _comma
}

# Format a boolean true/false keypair.  Booleans are unquoted.
# With '-n' or '--nocomma', we return '"key": value'
# Without either arg, we return '"key": value,'
# If the value is neither 'true' or 'false', an error will be thrown
# TO-DO: Extend to map extra bools
json_bool() {
  case "${1}" in
    (-n|--nocomma) shift 1; _comma="" ;;
    (*)            _comma="," ;;
  esac
  case "${2}" in
    (0|true)        _bool=true ;;
    (*[0-9]*|false) _bool=false ;;
    (*)             json_vorhees "Value not a recognised boolean" ;;
  esac
  printf -- '"%s": %s%s' "${1:-null}" "${_bool}" "${_comma}"
  unset -v _bool _comma
}
