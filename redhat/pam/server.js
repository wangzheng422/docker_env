var http = require('http'); // 1 - Import Node.js core module

var server = http.createServer(function (req, res) {   // 2 - creating server

    //handle incomming requests here..
    if (req.method === "GET") {
        res.writeHead(200, { "Content-Type": "text/html" });
        res.write('OK');
        res.end();
    } else if (req.method === "POST") {
    
        var body = "";
        req.on("data", function (chunk) {
            body += chunk;
        });

        req.on("end", function(){
            res.writeHead(200, { "Content-Type": "text/html" });
            res.end("OK");
        });
    } else if (req.method === "DELETE") {
    
        res.writeHead(200, { "Content-Type": "text/html" });
        res.end("OK");

    } 

});

server.listen(5000); //3 - listen for any incoming requests

console.log('Node.js web server at port 5000 is running..')