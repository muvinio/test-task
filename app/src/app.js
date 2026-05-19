const http = require("http");

const server = http.createServer((req, res) => {
  const headers = req.headers;

  res.writeHead(200, { "Content-Type": "application/json" });

  res.end(JSON.stringify({
    x_forwarded_for: headers["x-forwarded-for"] || null,
    remote_addr: req.socket.remoteAddress
  }, null, 2));
});

server.listen(3000, () => {
  console.log("App listening on port 3000");
});