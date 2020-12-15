PStream = require "./PStream"

class ParserState
  constructor: (props) ->  
    unless props.target instanceof PStream
      throw new TypeError "Target (#{props.target}) is not an instance of PStream"
    @target  = props.target
    @data    = props.data    or null
    @error   = props.error   or null
    @isError = props.isError or false
    @index   = props.index   or 0
    @result  = props.result
  
  props: -> ({
    target:  @target
    data:    @data
    error:   @error
    isError: @isError
    index:   @index
    result:  @result
  })
  
  # Welp, I guess this thing is useless
  errorProps: -> ({
    target:  @target
    data:    @data
    error:   @error
    isError: @isError
    index:   @index
    result:  @result
  })

  dataProps: -> ({
    result:  @result
    data:    @data
  })

  resultify: (result) -> new ParserState({ @props()..., error: null, isError: false, result })
  errorify:  (error)  -> new ParserState({ @props()..., error, isError: true, result: undefined })
  dataify:   (data)   -> new ParserState({ @props()..., data })
  update: (result, index) -> new ParserState({ @props()..., error: null, isError: false, result, index })
  
module.exports = ParserState
