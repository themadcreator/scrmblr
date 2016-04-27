fs           = require 'fs'
path         = require 'path'

nacl         = require('js-nacl').instantiate()
sodium       = require 'libsodium-wrappers'

xorThrough   = require './xor-through'
chunkThrough = require './chunk-through'


class NaclScrambler
  @DEFAULT_CHUNK_SIZE : 512
  @FORMAT_PREFIX : new Buffer('SCRMBLR', 'ASCII')

  constructor : (@context) ->

  serializeHeader : (metadata) ->
    serializedMetadata = JSON.stringify({
      file  : metadata.file
      key   : new Buffer(metadata.key).toString('base64')
      nonce : new Buffer(metadata.nonce).toString('base64')
      chunk : metadata.chunk
    })
    sealedMetadata = sodium.crypto_box_seal(nacl.encode_utf8(serializedMetadata), @context.boxPk)
    fields = [
      NaclScrambler.FORMAT_PREFIX
      new Buffer(Uint32Array.of(sealedMetadata.byteLength).buffer)
      new Buffer(sealedMetadata.buffer)
    ]
    return Buffer.concat(fields)

  parseHeader : (buffer) ->
    if not buffer.slice(0, NaclScrambler.FORMAT_PREFIX.length).equals(NaclScrambler.FORMAT_PREFIX)
      throw new Error("not a scrmblr file")

    buffer = buffer.slice(NaclScrambler.FORMAT_PREFIX.length)
    sealedMetadataLength = Uint32Array.from(buffer)[0]

    buffer = buffer.slice(4)
    serializedMetadata = nacl.decode_utf8(sodium.crypto_box_seal_open(buffer, @context.boxPk, @context.boxSk))
    metadata = JSON.parse(serializedMetadata)
    return {
      file  : metadata.file
      key   : Uint8Array.from(new Buffer(metadata.key, 'base64'))
      nonce : Uint8Array.from(new Buffer(metadata.nonce, 'base64'))
      chunk : metadata.chunk
    }

  scramble : (filePath) ->
    # generate metadata
    metadata =
      file  : path.basename(filePath)
      key   : nacl.random_bytes(nacl.crypto_stream_KEYBYTES)
      nonce : nacl.crypto_stream_random_nonce()
      chunk : 512

    # open output file for writing
    out = fs.createWriteStream(path.join(
      path.dirname(path.resolve(filePath))
      new Buffer(nacl.random_bytes(16)).toString('hex') + '.scrmblr'
    ))

    # write header
    out.write(@serializeHeader(metadata))

    # encrypt the rest of the file contents in chunks
    fs.createReadStream(filePath)
      .pipe(chunkThrough(metadata.chunk))
      .pipe(xorThrough(metadata.nonce, metadata.key))
      .pipe(out)
    return



  ###

  scramble : (file, context) ->
    header = @header(file)
    streamKey = nacl.random_bytes(nacl.crypto_stream_KEYBYTES)

    nonce = nacl.crypto_secretbox_random_nonce()

    nonce = nacl.crypto_stream_random_nonce()
    fs.open("#{new Buffer(nonce).toString('hex')}.scrmblr", "w").then((fd) ->

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
  ###


do ->
  ScrmblrContext = require './context'
  io = new ScrmblrContext()

  #context = io.init()
  #io.store(context, "password")

  context = io.load()
  # context = io.unlock(context, "password")

  scrmblr = new NaclScrambler(context)
  scrmblr.scramble('test.bin')


