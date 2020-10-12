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
  getCharacterLength
}