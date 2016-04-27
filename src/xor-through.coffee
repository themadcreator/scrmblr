through = require 'through'
sodium  = require 'libsodium-wrappers'
nacl    = require('js-nacl').instantiate()

xorThrough = (nonce, key) ->
  return through(
    (data) ->
      xored = nacl.crypto_stream_xor(data, nonce, key)
      sodium.increment(nonce)
      @queue(new Buffer(xored))
      return
  )

module.exports = xorThrough