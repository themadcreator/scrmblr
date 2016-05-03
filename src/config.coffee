nacl   = require('js-nacl').instantiate()
scrypt = require 'scrypt'
fs     = require 'fs'

class Configurator
  @DEFAULT_CONFIG_FILENAME : '.scrmblr.json'

  exists : ->
    return fs.existsSync(Configurator.DEFAULT_CONFIG_FILENAME)

  store : (config, password) ->
    cboxSk = @deriveKeyXor(password, config.salt, config.boxSk)
    fs.writeFileSync(Configurator.DEFAULT_CONFIG_FILENAME, JSON.stringify({
        salt   : new Buffer(config.salt).toString('base64')
        boxPk  : new Buffer(config.boxPk).toString('base64')
        cboxSk : new Buffer(cboxSk).toString('base64')
    }))
    return

  load : () ->
    config = JSON.parse(fs.readFileSync(Configurator.DEFAULT_CONFIG_FILENAME))
    return {
      salt   : new Uint8Array(new Buffer(config.salt, 'base64'))
      boxPk  : new Uint8Array(new Buffer(config.boxPk, 'base64'))
      cboxSk : new Uint8Array(new Buffer(config.cboxSk, 'base64'))
    }

  init : () ->
    keypair = nacl.crypto_box_keypair()
    salt    = nacl.crypto_stream_random_nonce()
    return {
      salt  : salt
      boxPk : keypair.boxPk
      boxSk : keypair.boxSk
    }

  unlock : (config, password) ->
    config.boxSk = @deriveKeyXor(password, config.salt, config.cboxSk)
    return config

  deriveKeyXor : (key, salt, message) ->
    derivedKey = scrypt.hashSync(key, {N:16, r:8, p:1}, nacl.crypto_stream_KEYBYTES, new Buffer(salt))
    return nacl.crypto_stream_xor(message, salt, derivedKey)

module.exports = new Configurator()