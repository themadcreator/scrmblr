commander = require 'commander'

commander
  .command('init [password]')
  .description('Initialize scrmblr (.scmblr.json)')
  .action((password, options) ->
    console.log('Initializing...')

    ScrmblrContext = require './context'
    scrmblr = new ScrmblrContext()
    context = scrmblr.init()
    scrmblr.store(context, password)

    console.log('Done')
  )

commander
  .command('scramble [file]')
  .description('Scrambles files')
  .action((pattern, options) ->
    console.log('Loading Context...')
    ScrmblrContext = require './context'
    scrmblr = new ScrmblrContext()
    context = scrmblr.load()

    console.log('Scrambling File...')
    NaclScrambler = require './nacl-stream'
    scrmblr = new NaclScrambler(context)
    scrmblr.scramble(pattern)

    console.log('Done')
  )

commander
  .command('unscramble [password] [file]')
  .description('Scrambles files')
  .action((password, pattern, options) ->
    console.log('Loading Context...')
    ScrmblrContext = require './context'
    scrmblr = new ScrmblrContext()
    context = scrmblr.unlock(scrmblr.load(), password)

    console.log('Unscrambling File...')
    NaclScrambler = require './nacl-stream'
    scrmblr = new NaclScrambler(context)
    scrmblr.unscramble(pattern)

    console.log('Done')
  )


nacl = require('js-nacl')



module.exports = ->
  commander.parse(process.argv)

