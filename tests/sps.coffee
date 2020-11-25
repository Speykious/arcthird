{ StringPStream } = require "../src/pstreams"

module.exports =
  a:        new StringPStream "a"
  abc:      new StringPStream "abc"
  xyz:      new StringPStream "xyz"
  nums:     new StringPStream "123456"
  numalphs: new StringPStream "123abc"
  alphnums: new StringPStream "abc123"
  hello:    new StringPStream "hello world"
  spaces:   new StringPStream "   hmmm"
  empty:    new StringPStream ""
  日本語:    new StringPStream "日本語"
  テスト:    new StringPStream "それはテストです。"