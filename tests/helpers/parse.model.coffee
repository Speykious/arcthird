# { inspect } = require "util"
Parser = require "../../src/Parser"

module.exports = (chai, utils) ->
  Assertion = chai.Assertion
  jsonify = JSON.stringify
  
  Assertion.addMethod "parse", (target) ->
    obj = this._obj
    state = obj.parse target
    parsed = utils.inspect target, false, 4
    this.assert(
      state.isError is false
      "expected parser to parse #{parsed}"
      "expected parser not to parse #{parsed}"
    )
  
  Assertion.addMethod "haveParseResult", (target, result) ->
    obj = this._obj
    state = obj.parse target
    this.assert(
      (jsonify state.result) is (jsonify result)
      "expected parsed result to be \#{exp}, got \#{act}"
      "expected parsed result not to be \#{act}"
      result
      state.result
    )

  Assertion.addMethod "haveParseData", (target, data) ->
    obj = this._obj
    state = obj.parse target
    this.assert(
      (jsonify state.data) is (jsonify data)
      "expected parser data to be \#{exp}, got \#{act}"
      "expected parser data not to be \#{act}"
      data
      state.data
    )
  
  Assertion.addMethod "haveParserState", (target, filter) ->
    obj = this._obj
    state = obj.parse target
    this.assert(
      (filter state) is true
      "expected parser state to pass filter"
      "expected parser state to not pass filter"
    )
  
  Assertion.addMethod "haveParseResultLike", (target, reResult) ->
    obj = this._obj
    state = obj.parse target
    this.assert(
      reResult.test state.result
      "expected parsed result to match \#{exp}, got \#{act}"
      "expected parsed result not to match \#{exp}, got \#{act}"
      reResult
      state.result
    )

  Assertion.addMethod "haveParseError", (target, error) ->
    obj = this._obj
    state = obj.parse target
    this.assert(
      state.error is error
      "expected parser to have error \#{exp}, got \#{act}"
      "expected parser to not have error \#{act}"
      error
      state.error
    )
  
  Assertion.addMethod "haveParseErrorLike", (target, reError) ->
    obj = this._obj
    state = obj.parse target
    this.assert(
      reError.test state.error
      "expected parser to have error matching \#{exp}, got \#{act}"
      "expected parser to not have error matching \#{exp}, got \#{act}"
      reError.toString()
      state.error
    )
  
  strings = [
    "hello world",
    "hello1234a",
    "",
    "12345 325vfs43",
    "!@#$%^",
    "≈ç√∫˜µ hgello skajb",
  ]
  
  Assertion.addMethod "parseLike", (parser) ->
    obj = this._obj
    strings.forEarch s -> (obj.parse s).should.equal parser.parse s
  