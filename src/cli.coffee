commander = require 'commander'
colors    = require 'colors'
Promise   = require 'bluebird'
glob      = Promise.promisify(require('glob'))

Config    = require './config'

commander
  .command('init <password>')
  .description('Initialize scrmblr (.scmblr.json)')
  .action((password, options) ->
    if Config.exists()
      console.log 'Configuration already exists!'.red
      console.log 'Aborting to prevent losing scrambled data'
      process.exit(1)

    process.stdout.write("Initializing... ")
    config = Config.init()
    Config.store(config, password)
    console.log('Done.')
  )

commander
  .command('scramble [file-pattern]')
  .description('Scrambles files')
  .action((pattern, options) ->
    if not Config.exists()
      console.log 'Uninitialized directory'.red
      console.log 'Run "scrmblr init [password]" to initialize'
      process.exit(1)

    pattern ?= '**/.'

    config = Config.load()
    console.log('Scrambling Files...')

    Scrambler = require './scrambler'
    scrmblr = new Scrambler(config)
    glob(pattern).then (files) -> files.forEach (file) ->
        process.stdout.write("Scrambling #{file} ...")
        scrmblr.scramble(file)

    console.log('Done.')
  )

commander
  .command('unscramble <password> [file-pattern]')
  .description('Unscrambles files')
  .action((password, pattern, options) ->
    pattern ?= '**/*.scrmblr'

    if not Config.exists()
      console.log 'Uninitialized directory'.red
      console.log 'Run "scrmblr init [password]" to initialize'
      process.exit(1)

    config = Config.unlock(Config.load(), password)
    console.log('Uncrambling Files...')

    Scrambler = require './scrambler'
    scrmblr = new Scrambler(config)
    glob(pattern).then (files) -> files.forEach (file) ->
      process.stdout.write("Unscrambling #{file} ...")
      scrmblr.unscramble(file)

    console.log('Done')
  )

module.exports = ->
  if process.argv.length < 3 then commander.help()
  commander.parse(process.argv)

