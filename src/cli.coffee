commander = require 'commander'

commander
  .command('init')
  .description('Initialize scrmblr (.scmblr.json)')
  .action((options) ->
    console.log 'initting'
  )

commander
  .command('scramble [file-pattern]')
  .description('Scrambles files')
  .action((pattern, options) ->
    console.log 'scrambling'
  )

commander
  .command('unscramble [file-pattern]')
  .description('Scrambles files')
  .action((pattern, options) ->
    console.log 'unscrambling'
  )


nacl = require('js-nacl')



module.exports = ->
  commander.parse(process.argv)

