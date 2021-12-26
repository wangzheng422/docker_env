var express = require('express');
var path = require('path');
var app = express();

app.post('/', function(req, res){
    res.contentType('application/xml');
    res.sendFile(path.join(__dirname , 'data.xml'));
});



var server = app.listen(5000, () => {
	console.log('Started listening on 5000');
});