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

  errorProps: -> ({
    data:   @data
    error:  @error
    index:  @index
  })

  dataProps: -> ({
    result: @result
    data: @data
  })

  resultify: (result) -> new ParserState({ ...@props(), result })
  errorify:  (error)  -> new ParserState({ ...@props(), error })
  dataify:   (data)   -> new ParserState({ ...@props(), data })
  update: (result, index) -> new ParserState({ ...@props(), result, index })

class Parser
  # Parser :: Iterable t => (ParserState t * d -> ParserState t a d) -> Parser t a d
  constructor: (@pf) ->

  # parse :: Iterable t => Parser t a d ~> t -> ParserState t a d
  parse: (target) -> @pf new ParserState { target }

  # fork :: Iterable t => Parser t a d ~> (t, (ParserState t a d -> x), (ParserState t a d -> y)) -> (Either x y)
  fork: (target, errf, succf) ->
    state = @pf new ParserState { target }
    return (if state.error then errf else succf) state

  # map :: Iterable t => Parser t a d ~> (a -> b) -> Parser t b d
  map: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else state.resultify f state.result
  
  # chain :: Iterable t -> Parser t a d ~> (a -> Parser t b d) -> Parser t b d
  chain: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else (f state.result).pf state
  
  # ap :: Iterable t -> Parser t a d ~> Parser t (a -> b) d -> Parser t b d
  ap: (poff) ->
    pf = @pf
    return new Parser (s) ->
      if s.error then return s
      argstate = pf s
      if argstate.error then return argstate
      fnstate = poff.pf argstate
      if fnstate.error then return fnstate
      return fnstate.resultify fnstate.result argstate.result
  
  # errorMap :: Iterable t => Parser t a d ~> (Parser t a d -> String) -> Parser t a d
  errorMap: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return unless state.error then state
      else state.errorify f state.errorProps()
    
  # errorChain :: Iterable t => Parser t a d ~> ({String, Int, d} -> Parser t a d) -> Parser t a d
  errorChain: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return unless state.error then state
      else (f state.errorProps()).pf state
  
  # mapFromData :: Iterable t => Parser t a d ~> ({a, d} -> b) -> Parser t b d
  mapFromData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else state.resultify f state.dataProps()

  # chainFromData :: Iterable t => Parser t a d ~> ({a, d} -> Parser t b e) -> Parser t b e
  chainFromData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else (f state.dataProps()).pf state

  mapData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return state.dataify f state.data

  @of: (x) -> new Parser (s) -> s.resultify(x)

  