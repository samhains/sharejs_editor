connect = require("connect")
share   = require("share").server
refspec = require("./refspec")

if process.platform == "darwin"
  db_socket = "/tmp"
else
  db_socket = "/var/run/postgresql"

env = process.env["NODE_ENV"] || "development"

options = {
  db:
    type:                  "pg"
    host:                  db_socket
    database:              "tc_#{env}"
    document_name_column:  "article_draft_uid"
    operations_table:      "article_draft_operations"
    snapshot_table:        "article_draft_snapshots"
    keep_snapshots:        true

  host: '0.0.0.0'
  port: process.env["PORT"] || 9000
  staticpath: null,
  create_tables_automatically: (env == 'development')
}

# Catch 0.8.20 http hangup exceptions—create a domain for every request
# http://clock.co.uk/tech-blogs/preventing-http-raise-hangup-error-on-destroyed-socket-write-from-crashing-your-nodejs-server
try
  domain = require("domain")

  hangupSilencer = (req, res, next) ->
    reqd = domain.create()
    reqd.add req
    reqd.add res
    reqd.on 'error', (error) ->
      if error.code isnt 'ECONNRESET'
        console.error(error, req.url)
        reqd.dispose()
    next()

  serverRunner = (next) ->
    domain.create().run next

catch e
  hangupSilencer = (req, res, next) ->
    next()

  serverRunner = (next) ->
    next()

cors = (request, response, next) ->
  response.setHeader "Access-Control-Allow-Origin", "*"
  response.setHeader "Access-Control-Max-Age",      "3600"
  next()

serverRunner ->
  server = connect hangupSilencer,
    cors,
    connect.logger(),
    refspec(),
    connect.static(__dirname + '/public')

  share.attach server, options

  server.listen options.port, options.host

  console.log "Server running at http://127.0.0.1:#{options.port}/ connecting to #{options.db.database}"
