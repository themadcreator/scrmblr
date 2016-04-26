nacl   = require('js-nacl').instantiate()
scrypt = require 'scrypt'
fs     = require 'fs'

class ScrmblrContext
  constructor : (path) ->

  store : (context, password) ->
    cboxSk = @deriveKeyXor(password, context.salt, context.boxSk)
    fs.writeFileSync('.scrmblr.json', JSON.stringify({
        salt   : new Buffer(context.salt).toString('base64')
        boxPk  : new Buffer(context.boxPk).toString('base64')
        cboxSk : new Buffer(cboxSk).toString('base64')
    }))
    return

  load : () ->
    context = JSON.parse(fs.readFileSync('.scrmblr.json'))
    return {
      salt   : new Uint8Array(new Buffer(context.salt, 'base64'))
      boxPk  : new Uint8Array(new Buffer(context.boxPk, 'base64'))
      cboxSk : new Uint8Array(new Buffer(context.cboxSk, 'base64'))
    }

  init : () ->
    keypair = nacl.crypto_box_keypair()
    salt    = nacl.crypto_stream_random_nonce()
    return {
      salt  : salt
      boxPk : keypair.boxPk
      boxSk : keypair.boxSk
    }

  unlock : (context, password) ->
    context.boxSk = @deriveKeyXor(password, context.salt, context.cboxSk)
    return context

  deriveKeyXor : (key, salt, message) ->
    derivedKey = scrypt.hashSync(key, {N:16, r:8, p:1}, nacl.crypto_stream_KEYBYTES, new Buffer(salt))
    return nacl.crypto_stream_xor(message, salt, derivedKey)

module.exports = ScrmblrContext