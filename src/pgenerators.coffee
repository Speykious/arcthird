{ reDigit, reDigits, reLetter, reLetters, reWhitespaces } = require "./constants"
{ charlength, insp } = require "./helpers"
{ encoder, StringPStream } = require "./pstreams"
Parser = require "./Parser"
{ possibly } = require "./pcombinators"

# char :: StringPStream t => Char -> Parser t Char d
char = (c) ->
  unless c and typeof c is "string" and (charlength c) is 1
    throw new TypeError "char must be called with a single character, got #{insp c} instead"
  return new Parser (s) ->
    unless s.target instanceof StringPStream
      throw new TypeError "char expects a StringPStream instance as target, got #{typeof s.target} instead"
    if s.isError then return s
    { index, target } = s
    targetLength = target.length()
    if index < targetLength
      charWidth = target.getCharWidth index
      if index + charWidth <= targetLength
        char = target.getUtf8Char index, charWidth
        return if char is c then s.update c, index + 1
        else s.errorify "ParseError (position #{index}): Expecting character #{insp c}, got #{insp char}"
    return s.errorify "ParseError (position #{index}): Expecting character #{insp c}, got end of input"

# anyChar :: StringPStream t => Parser t Char d
anyChar = new Parser (s) ->
  unless s.target instanceof StringPStream
    throw new TypeError "anyChar expects a StringPStream instance as target, got #{typeof s.target} instead"
  if s.isError then return s
  { index, target } = s
  targetLength = target.length()
  if index < targetLength
    charWidth = target.getCharWidth index
    if index + charWidth <= targetLength
      char = target.getUtf8Char index, charWidth
      return s.update char, index + 1
  return s.errorify "ParseError (position #{index}): Expecting any character, got end of input"

# peek :: Parser
peek = new Parser (s) ->
  if s.isError then return s
  { index, target } = s
  return if index < target.length() then s.resultify target.elementAt index
  else s.errorify "ParseError (position #{index}): Unexpected end of input"

# str :: StringPStream t => String -> Parser t String d
str = (xs) ->
  unless xs and typeof xs is "string" and (charlength xs) > 0
    throw new TypeError "str must be called with a string with length > 0, got #{xs}"
  es = encoder.encode xs
  return new Parser (s) ->
    unless s.target instanceof StringPStream
      throw new TypeError "char expects a StringPStream instance as target, got #{typeof s.target} instead"
    if s.isError then return s
    { index, target } = s
    remainingBytes = target.length() - index
    if remainingBytes < es.byteLength
      return s.errorify "ParseError (position #{index}): Expecting string '#{xs}', got end of input"
    sai = target.getString index, es.byteLength
    return if xs is sai then s.update xs, index + xs.length
    else s.errorify "ParseError (position #{index}): Expecting string '#{xs}', got '#{sai}...'"

# regex :: StringPStream t => RegExp -> Parser t String d
regex = (re) ->
  unless re instanceof RegExp
    throw new TypeError "regex must be called with a RegExp"
  unless re.source[0] is "^"
    throw new Error "regex parser must contain '^' start assertion"
  return new Parser (s) ->
    unless s.target instanceof StringPStream
      throw new TypeError "regex expects a StringPStream instance as target, got #{typeof target} instead"
    if s.isError then return s
    { target, index } = s
    rest = target.getString index, target.length() - index
    if rest.length < 1
      return s.errorify "ParseError (position #{index}): Expecting string matching '#{re}', got end of input"
    match = rest.match re
    return if match then s.update match[0], index + match[0].length
    else s.errorify "ParseError (position #{index}: Expecting string matching '#{re}', got '#{rest.slice 0, 5}...'"

# digit :: Parser String String d
digit = new Parser (s) ->
  unless s.target instanceof StringPStream
    throw new TypeError "digit expects a StringPStream instance as target, got #{typeof target} instead"
  if s.isError then return s
  { target, index } = s
  targetLength = target.length()  
  if index < targetLength
    charWidth = target.getCharWidth index
    if index + charWidth <= targetLength
      char = target.getUtf8Char index, charWidth
      return if reDigit.test char then s.update char, index + 1
      else s.errorify "ParseError (position #{index}): Expecting digit, got '#{char}'"
  return s.errorify "ParseError (position #{index}): Expecting digit, got end of input"

# digits :: Parser String String d
digits = (regex reDigits).errorMap ({ index }) ->
  "ParseError (position #{index}): Expecting digits"

# letter :: Parser String String d
letter = new Parser (s) ->
  unless s.target instanceof StringPStream
    throw new TypeError "letter expects a StringPStream instance as target, got #{typeof target} instead"
  if s.isError then return s
  { target, index } = s
  targetLength = target.length()  
  if index < targetLength
    charWidth = target.getCharWidth index
    if index + charWidth <= targetLength
      char = target.getUtf8Char index, charWidth
      return if reLetter.test char then s.update char, index + charWidth
      else s.errorify "ParseError (position #{index}): Expecting letter, got '#{char}'"
  return s.errorify "ParseError (position #{index}): Expecting letter, got end of input"

# letters :: Parser String String d
letters = (regex reLetters).errorMap ({ index }) ->
  "ParseError (position #{index}): Expecting letters"

# anyOfString :: String -> Parser String Char d
anyOfString = (xs) ->
  unless xs and typeof xs is "string" and (charlength xs) > 0
    throw new TypeError "str must be called with a string with length > 0, got #{xs}"
  new Parser (s) ->
    unless s.target instanceof StringPStream
      throw new TypeError "anyOfString expects a StringPStream instance as target, got #{typeof target} instead"
    if s.isError then return s
    { target, index } = s
    targetLength = target.length()  
    if index < targetLength
      charWidth = target.getCharWidth index
      if index + charWidth <= targetLength
        char = target.getUtf8Char index, charWidth
        return if xs.includes char then s.update char, index + charWidth
        else s.errorify "ParseError (position #{index}): Expecting any of the string '#{xs}', got '#{char}'"
    return s.errorify "ParseError (position #{index}): Expecting any of the string '#{xs}', got end of input"

# endOfInput :: PStream t => Parser t Null d
endOfInput = new Parser (s) ->
  if s.isError then return s
  { target, index } = s
  return if index isnt target.length()
  then s.errorify "ParseError 'endOfInput' (position #{index}): Expected end of input, got '#{target.elementAt index}'"
  else s.resultify null

# whitespace :: StringPStream t => Parser t String d
whitespace = (regex reWhitespaces).errorMap ({ index }) ->
  "ParseError 'whitespace' (position #{index}): Expecting to match at least one space"

# optionalWhitespace :: StringPStream t => Parser t String d
optionalWhitespace = (possibly whitespace).map (x) -> x or ""

module.exports = {
  char, anyChar, peek, str
  regex, digit, digits
  letter, letters
  anyOfString, endOfInput
  whitespace, optionalWhitespace
}