through = require 'through'
chunkThrough = (chunksize) ->
  buffers = []
  bytesInBuffer = 0

  consolidateChunk = ->
    bytesRemaining = chunksize
    chunk = new Buffer(chunksize)

    while bytesRemaining > 0 and buffers.length > 0
      # get next buffer
      buffer = buffers.shift()

      # if the buffer is small enough to fit in chunk, copy all of it
      if buffer.length < bytesRemaining
        buffer.copy(chunk, chunksize - bytesRemaining)
        bytesRemaining -= buffer.length

      # otherwise, split the buffer
      else
        buffer.copy(chunk, chunksize - bytesRemaining, 0, bytesRemaining)
        buffers.unshift(buffer.slice(bytesRemaining, buffer.length))
        bytesRemaining = 0

    if bytesRemaining != 0
      chunk = chunk.slice(0, chunksize - bytesRemaining)

    return chunk


  return through(
    (data) ->
      bytesInBuffer += data.length
      buffers.push(data)

      while bytesInBuffer >= chunksize
        @queue(chunk = consolidateChunk())
        bytesInBuffer -= chunk.length
    ,
    () ->
      while bytesInBuffer > 0
        @queue(chunk = consolidateChunk())
        bytesInBuffer -= chunk.length
      @queue(null)
  )

module.exports = chunkThrough

###
do ->
  fs = require 'fs'
  fs.createReadStream('test.bin')
    .pipe(chunkThrough(25612))
    .pipe(through((data) -> console.log(data.length)))
###
