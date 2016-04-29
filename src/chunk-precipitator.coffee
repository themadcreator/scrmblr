
class ChunkPrecipitator

  constructor : ->
    @buffers =  []
    @bytesInBuffer = 0

  push : (buffer) ->
    @buffers.push(buffer)
    @bytesInBuffer += buffer.length

  precipitate : (chunksize) ->
    bytesRemaining = chunksize
    chunk = new Buffer(chunksize)

    while bytesRemaining > 0 and @buffers.length > 0
      # get next buffer
      buffer = @buffers.shift()

      # if the buffer is small enough to fit in chunk, copy all of it
      if buffer.length < bytesRemaining
        buffer.copy(chunk, chunksize - bytesRemaining)
        bytesRemaining -= buffer.length

      # otherwise, split the buffer
      else
        buffer.copy(chunk, chunksize - bytesRemaining, 0, bytesRemaining)
        @buffers.unshift(buffer.slice(bytesRemaining, buffer.length))
        bytesRemaining = 0

    # if we didn't reach chunksize, truncate output
    if bytesRemaining != 0
      chunk = chunk.slice(0, chunksize - bytesRemaining)

    @bytesInBuffer -= chunk.length
    return chunk

module.exports = ChunkPrecipitator