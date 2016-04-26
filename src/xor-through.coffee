through = require 'through'
sodium  = require 'libsodium-wrappers'
nacl    = require('nacl-js').initiate()

xorThrough = (nonce, key) ->
  return through(
    (data) ->
      xored = nacl.crypto_stream_xor(data, nonce, key)
      nonce = sodium.increment(nonce)
      @queue(xored)
      return
  )

module.exports = {
  xor : xorThrough
}