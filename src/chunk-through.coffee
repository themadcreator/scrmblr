through = require 'through'
ChunkPrecipitator = require './chunk-precipitator'

module.exports = chunkThrough = (chunksize) ->
  precipitator = new ChunkPrecipitator()
  return through(
    (data) ->
      precipitator.push(data)
      while precipitator.bytesInBuffer >= chunksize
        @queue(chunk = precipitator.precipitate(chunksize))
    ,
    () ->
      while precipitator.bytesInBuffer > 0
        @queue(chunk = precipitator.precipitate(chunksize))
      @queue(null)
  )

module.exports = chunkThrough
