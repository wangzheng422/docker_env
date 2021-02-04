var http = require('http');
var fs = require('fs'); // 1 - Import Node.js core module

var server = http.createServer(function (req, res) {   // 2 - creating server
    console.log(req.method);
    console.log(req.headers);
    console.log(req.url); 
    //handle incomming requests here..
    if (req.method === "GET") {
        
        // res.writeHead(200, { "Content-Type": "application/xml" });
        fs.readFile("data.json", function(err, data){
            if(err){
              res.statusCode = 500;
              res.end(`Error getting the file: ${err}.`);
            } else {
              // if the file is found, set Content-type and send data
              res.setHeader('Content-type', "application/json" );
              res.end(data);
            }
          });
        // res.write('<html><body><p>This is home Page.</p></body></html>');
        // res.end();
    } else if (req.method === "POST") {
    
        var body = "";
        req.on("data", function (chunk) {
            body += chunk;
        });

        req.on("end", function(){
            res.writeHead(200, { "Content-Type": "application/xml" });
            res.end("<html><body><p>This is home Page.</p></body></html>");
        });
    } else if (req.method === "DELETE") {
    
        res.writeHead(200, { "Content-Type": "application/xml" });
        res.end("<html><body><p>This is home Page.</p></body></html>");

    } 

});

server.listen(5000); //3 - listen for any incoming requests

console.log('Node.js web server at port 5000 is running..')