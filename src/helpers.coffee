{ inspect } = require "util"

# charlength :: String -> Int
charlength = (str) ->
  total = 0
  i = 0
  while i < str.length
    cp = str.codePointAt(i)
    while cp
      cp = cp >> 8
      i++
    total++
  return total

# isTypedArray :: x -> Bool
isTypedArray = (x) ->
  x instanceof Uint8Array        ||
  x instanceof Uint8ClampedArray ||
  x instanceof Int8Array         ||
  x instanceof Uint16Array       ||
  x instanceof Int16Array        ||
  x instanceof Uint32Array       ||
  x instanceof Int32Array        ||
  x instanceof Float32Array      ||
  x instanceof Float64Array

insp = (o) -> inspect o, false, 4

module.exports = {
  charlength
  isTypedArray
  insp
}