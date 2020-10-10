# isIterable :: o -> Bool
isIterable = (o) ->
  # checks for null and undefined
  if o is null or o is undefined then false
  else typeof o[Symbol.iterator] is 'function'

# getCharacterLength :: String -> Int
getCharacterLength = (str) ->
  total = 0
  i = 0
  while i < str.length
    cp = str.codePointAt(i)
    while cp
      cp = cp >> 8
      i++
    total++
  return total

module.exports = {
  isIterable
  getCharacterLength
}