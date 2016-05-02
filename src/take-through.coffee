through = require 'through'
ChunkPrecipitator = require './chunk-precipitator'

module.exports = takeThrough = (takeBytes, callback) ->
  flowing = false
  precipitator = new ChunkPrecipitator()
  return through(
    (data) ->
      if flowing then return @queue(data)

      precipitator.push(data)
      if precipitator.bytesInBuffer >= takeBytes
        callback(precipitator.precipitate(takeBytes))
        for buffer in precipitator.buffers then @queue(buffer)
        flowing = true
  )

module.exports = takeThrough

###
do ->
  fs = require 'fs'
  strm = fs.createReadStream('scrambled.scrmblr')

  x = strm.pipe(takeThrough(7, (prefix) ->
    console.log(prefix.toString('ASCII'))
    x.pipe(takeThrough(4, (b) ->
      len = Uint32Array.from(b)[0]
      console.log len
    ))
  ))
###