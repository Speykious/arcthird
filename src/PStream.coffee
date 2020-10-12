# class PStream a
class PStream
  constructor: (@structure) ->
    @index = 0

  # length :: () -> Int
  length: ->
    throw new Error "The 'length' function has not been implemented"
  
  # elementAt :: Int -> a
  elementAt: (i) ->
    throw new Error "The 'next' function has not been implemented"
  
  # next :: () -> a
  next: -> @elementAt @index++
  
  # isTypedArray :: () -> Bool
  isTypedArray: ->
    @structure instanceof Uint8Array        ||
    @structure instanceof Uint8ClampedArray ||
    @structure instanceof Int8Array         ||
    @structure instanceof Uint16Array       ||
    @structure instanceof Int16Array        ||
    @structure instanceof Uint32Array       ||
    @structure instanceof Int32Array        ||
    @structure instanceof Float32Array      ||
    @structure instanceof Float64Array

module.exports = PStream