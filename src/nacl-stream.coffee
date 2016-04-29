fs   = require 'fs'
path = require 'path'

nacl   = require('js-nacl').instantiate()
sodium = require 'libsodium-wrappers'

chunkThrough = require './chunk-through'
xorThrough   = require './xor-through'
takeThrough  = require './take-through'

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

  extractHeader : (input, metadataCallback) ->
    x = input.pipe(takeThrough(NaclScrambler.FORMAT_PREFIX.length, (prefix) ->
        if not prefix.equals(NaclScrambler.FORMAT_PREFIX) then throw new Error("not a scrmblr file")
    )).pipe(takeThrough(4, (b) =>
      sealedMetadataByteLength = Uint32Array.from(b)[0]
      remainder = x.pipe(takeThrough(sealedMetadataByteLength, (sealedMetadata) =>
        serializedMetadata = nacl.decode_utf8(sodium.crypto_box_seal_open(Uint8Array.from(sealedMetadata), @context.boxPk, @context.boxSk))
        metadata = JSON.parse(serializedMetadata)

        metadataCallback(remainder, {
          file  : metadata.file
          key   : Uint8Array.from(new Buffer(metadata.key, 'base64'))
          nonce : Uint8Array.from(new Buffer(metadata.nonce, 'base64'))
          chunk : metadata.chunk
        })
      ))
    ))
    return

  scramble : (filePath) ->
    metadata =
      file  : path.basename(filePath)
      key   : nacl.random_bytes(nacl.crypto_stream_KEYBYTES)
      nonce : nacl.crypto_stream_random_nonce()
      chunk : 512

    output = fs.createWriteStream('scrambled.scrmblr')
    output.write(@serializeHeader(metadata))

    input = fs.createReadStream(filePath)
    input
      .pipe(chunkThrough(metadata.chunk))
      .pipe(xorThrough(metadata.nonce, metadata.key))
      .pipe(output)

  unscramble : (filePath) ->
    @extractHeader(fs.createReadStream(filePath), (remainder, metadata) ->
      output = fs.createWriteStream('unscrambled.scrmblr') # use metadata.file
      remainder
        .pipe(chunkThrough(metadata.chunk))
        .pipe(xorThrough(metadata.nonce, metadata.key))
        .pipe(output)
    )


module.exports = NaclScrambler

