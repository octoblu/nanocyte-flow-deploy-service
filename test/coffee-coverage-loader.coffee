path = require 'path'
coffeeCoverage = require 'coffee-coverage'
projectRoot = path.resolve __dirname, ".."
coverageVar = coffeeCoverage.findIstanbulVariable()

# Only write a coverage report if we're not running inside of Istanbul.
writeOnExit = path.join projectRoot, '/coverage/coverage-coffee.json' unless coverageVar?

coffeeCoverage.register
  instrumentor: 'istanbul'
  basePath: projectRoot
  exclude: ['/test', '/node_modules', '/.git', '/server.coffee']
  coverageVar: coverageVar
  writeOnExit: writeOnExit
  initAll: true
