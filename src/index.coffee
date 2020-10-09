# Caching compiled regexs for better performance
reDigit = /[0-9]/
reDigits = /^[0-9]+/
reLetter = /[a-zA-Z]/
reLetters = /^[a-zA-Z]+/
reWhitespaces = /^\s+/

isIterable = (o) ->
  # checks for null and undefined
  if o is null or o is undefined then false
  else typeof o[Symbol.iterator] is 'function'

class ParserState
  constructor: (props) ->
    unless isIterable props.target
      throw new Error "Target (#{props.target}) is not iterable"
    @target = props.target
    @data   = props.data   or null
    @error  = props.error  or null
    @index  = props.index  or 0
    @result = props.result or null
  
  props: -> ({
    target: @target
    data:   @data
    error:  @error
    index:  @index
    result: @result
  })

  resultify: (result) -> new ParserState({ ...@props(), result })
  errorify:  (error)  -> new ParserState({ ...@props(), error })
  dataify:   (data)   -> new ParserState({ ...@props(), data })
  update: (result, index) -> new ParserState({ ...@props(), result, index })

class Parser
  # Parser :: Iterable t => (ParserState t * -> ParserState t a) -> Parser t a
  constructor: (@pf) ->

  # parse :: Iterable t => Parser t a ~> t -> ParserState t a
  parse: (target) -> @pf new ParserState { target }

  # fork :: Iterable t => Parser t a ~> (t, (ParserState t a -> x), (ParserState t a -> y)) -> (Either x y)
  fork: (target, errf, succf) ->
    state = @pf new ParserState { target }
    return (if state.error then errf else succf) state

  # map :: Iterable t => Parser t a ~> (a -> b) -> Parser t b
  map: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else state.resultify f state.result
  
  # chain :: Iterable t -> Parser t a ~> (a -> Parser t b) -> Parser t b
  chain: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else (f state.result).pf state
  
  