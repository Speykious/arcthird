PStream = require "./PStream"

class ParserState
  constructor: (props) ->  
    unless props.target instanceof PStream
      throw new Error "Target (#{props.target}) is not an instance of PStream"
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
    data:   @data
  })

  resultify: (result) -> new ParserState({ @props()..., result })
  errorify:  (error)  -> new ParserState({ @props()..., error })
  dataify:   (data)   -> new ParserState({ @props()..., data })
  update: (result, index) -> new ParserState({ @props()..., result, index })
  
module.exports = ParserState