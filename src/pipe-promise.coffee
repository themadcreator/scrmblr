Promise = require 'bluebird'

takeThrough = require './take-through'

pipePromise = (input) ->
  promise = new Promise((resolve, reject) ->
    input.on 'end', resolve
    input.on 'error', reject
  )


  for key, method of input
    if typeof method is 'function'
      promise[key] = method.bind(input)

  promise.take = (byteLength) ->
    return new Promise((resolve, reject) ->
      newPipe = promise.pipe(takeThrough(byteLength, (buffer) ->
        resolve.call(promise, buffer)
      ))
    )

  return promise


###

extractHeader : (input, metadataCallback) ->
    x = input.pipe(takeThrough(Scrambler.FORMAT_PREFIX.length, (prefix) ->
        if not prefix.equals(Scrambler.FORMAT_PREFIX) then throw new Error("not a scrmblr file")
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
###

takeThrough = require './take-through'
through = require 'through'
promisePipe = ->
  context = through((data) -> @queue(data))

  api = (raw) -> 
  
    ### end = new Promise((resolve, reject) ->
      raw.on 'end', resolve
      raw.on 'error', reject
    )
    ###

    Object.assign(raw, {
      take : (num) ->
        deferred = Promise.pending()
        context = api(context.pipe(takeThrough(num, deferred.resolve)))
        return api(deferred.promise)

      drain : ->
        context = context.pipe(through((data) -> @queue(data)))
    })
    return raw
  return api(context)


do ->
  fs = require 'fs'
  stream = fs.createReadStream('test.bin')

  stream.pipe(promisePipe()
    .take(4).then((b) ->
      console.log b
    ).drain() #.then((b) -> console.log b)
  )

###
  pp = pipePromise(stream)
  pp.take(4).then((b) ->
    console.log b
    console.log @
    @take(6)
  ).then (b) -> console.log b
###