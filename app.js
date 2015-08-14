var express = require('express'),
  sharejs = require('share').server,
  client = require('share').client;

var connString = 'postgres://@localhost/ideas_development';

var server = express();
server.use(express.static(__dirname + '/public'));

var port = 8000;
var options = {
  db: {
    type: 'pg',
    uri: 'postgres://@localhost/ideas_development' ,
    create_tables_automatically: true
  },
  browserChannel: {cors: '*'},
  auth: function(client, action) {
    // This auth handler rejects any ops bound for docs starting with 'readonly'.
    if (action.name === 'submit op' && action.docName.match(/^readonly/)) {
      action.reject();
    } else {
      action.accept();
    }
  }
};

// enable redis persistance
try {
  require('redis');
  options.db = {type: 'redis'};
} catch (e) {}


// Attach the sharejs REST and Socket.io interfaces to the server
sharejs.attach(server, options);


server.get('/', function(req, res, next) {
  res.writeHead(302, {location: '/index.html'});
  res.end();
});
server.listen(port);
console.log("running at http://localhost:" + port);

process.title = 'sharejs';
process.on('uncaughtException', function (err) {
  console.log('error!');
});
