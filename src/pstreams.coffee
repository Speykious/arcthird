PStream = require "./PStream"
{ isTypedArray } = require "./helpers"

text = {}
if typeof TextEncoder isnt "undefined"
  text.Encoder = TextEncoder
  text.Decoder = TextDecoder
else
  try
    util = require "util"
    text.Encoder = util.TextEncoder
    text.Decoder = util.TextDecoder
  catch e
    throw new Error "Arcthird requires TextEncoder and TextDecoder to be polyfilled."
  
encoder = new text.Encoder()
decoder = new text.Decoder()


class StringPStream extends PStream
  constructor: (target) ->
    dataView = undefined
    if typeof target is "string"
      bytes = encoder.encode target
      dataView = new DataView bytes.buffer
    else if target instanceof ArrayBuffer
      dataView = new DataView target
    else if isTypedArray target
      dataView = new DataView target.buffer
    else if target instanceof DataView
      dataView = target
    else
      throw new Error "Target must be a string, ArrayBuffer, TypedArray or DataView, got #{Object.prototype.toString.call target}"
    
    super dataView
  
  length: -> @structure.byteLength
  elementAt: (i) -> @structure.getUint8 i
  
  getString: (index, length) ->
    structure = @structure
    bytes = Uint8Array.from { length }, (_, i) ->
      structure.getUint8 index + i
    return decoder.decode bytes

  getUtf8Char: (index, length) ->
    dvs = @structure
    bytes = Uint8Array.from { length }, (_, i) ->
      dvs.getUint8 index + i
    return decoder.decode bytes
  
  getCharWidth: (index) ->
    byte = @structure.getUint8 index
    return if (byte & 0x80) >> 7 is 0 then 1
    else if (byte & 0xe0) >> 5 is 0b110 then 2
    else if (byte & 0xf0) >> 4 is 0b1110 then 3
    else if (byte & 0xf0) >> 4 is 0b1111 then 4
    else 1
  
module.exports = {
  encoder, decoder
  StringPStream
}