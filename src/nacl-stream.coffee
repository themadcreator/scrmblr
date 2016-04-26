nacl   = require('js-nacl').instantiate()
path   = require 'path'
crypto = require 'crypto'
scrypt = require 'scrypt'
sodium = require 'libsodium-wrappers'

Promise = require 'bluebird'
fs = Promise.promisifyAll(require('fs'))

class NaclScrambler
  init : (password) ->
    # generate keypair
    keypair = nacl.crypto_box_keypair()

    # encrypt secret key with scrypt derived key
    salt    = nacl.crypto_stream_random_nonce()
    c_boxSk = @deriveKeyXor(password, salt, keypair.boxSk)

    return {
      salt  : new Buffer(salt).toString('base64')
      boxPk : new Buffer(keypair.boxPk).toString('base64')
      boxSk : new Buffer(c_boxSk).toString('base64')
    }

  open : (context, password) ->
    salt    = new Uint8Array(new Buffer(context.salt, 'base64'))
    c_boxSk = new Uint8Array(new Buffer(context.boxSk, 'base64'))
    boxSk   = @deriveKeyXor(password, salt, c_boxSk)
    return {
      boxPk : new Uint8Array(new Buffer(context.boxPk, 'base64'))
      boxSk : boxSk
    }

  deriveKeyXor : (key, salt, message) ->
    derivedKey = scrypt.hashSync(key, {N:16, r:8, p:1}, nacl.crypto_stream_KEYBYTES, new Buffer(salt))
    return nacl.crypto_stream_xor(message, salt, derivedKey)

  header : (filepath) ->
    encoded_filename = nacl.encode_utf8(path.basename(filepath))
    header = new Uint8Array(HEADER_BLOCK_SIZE = 8)
    headerView = new DataView(runlength.buffer)
    headerView.setUint32(0, encoded_filename.length)
    headerView.setUint32(4, blocksize = 512)


  scramble : (file, context) ->
    header = @header(file)
    streamKey = nacl.random_bytes(nacl.crypto_stream_KEYBYTES)

    nonce = nacl.crypto_secretbox_random_nonce()
    c = nacl.crypto_secretbox(key, nonce, context.);
m1 = nacl.crypto_box_seal(c, n, context.boxPk);

    nonce = nacl.crypto_stream_random_nonce()
    fs.open("#{new Buffer(nonce).toString('hex')}.scmblr", "w").then((fd) ->

      fs.write(fd, nacl.crypto_stream_xor(header, nonce, key), 0).then ->
        writeBlock = ->
      )


    )

    fs.write(fd, 0)



    # pipe to files
    data = new Uint8Array(c_header.length + c_filename.length)
    data.set(c_header, 0)
    data.set(c_filename, c_header.length)
    return data


  # integer addition of 1 on uint8array
  increment : (arr) ->
    for i in [0...arr.length]
      arr[i]++
      break if arr[i] # break unless carry
    return arr

  unscramble : (data, nonce, key) ->

    # unscramble
    d_preamble = nacl.crypto_stream_xor(data.slice(0, 4), nonce, key)
    filenameLength = new DataView(d_preamble.buffer).getUint32(0)
    d_filename = nacl.crypto_stream_xor(data.slice(4, 4 + filenameLength), @increment(nonce), key)
    console.log nacl.decode_utf8(d_filename)

do ->


    # save public key and encrypted secret key to disk
    fs.writeFileSync('.scrmblr.json', JSON.stringify())
    context = JSON.parse(fs.readFileSync('.scrmblr.json'))


  ###
  key = nacl.random_bytes(nacl.crypto_stream_KEYBYTES)
  scmblr = new NaclScrambler()
  data = scmblr.scramble("filetest.txt", key)
  console.log scmblr.unscramble(data, )
  scmblr = new NaclScrambler()
  scmblr.init("password")
  scmblr.prepare("password")
  ###