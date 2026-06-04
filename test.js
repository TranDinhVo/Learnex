const http = require('http');
const req = http.request({
  hostname: 'localhost',
  port: 8080,
  path: '/api/auth/login',
  method: 'POST',
  headers: { 'Content-Type': 'application/json' }
}, res => {
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => {
    const token = JSON.parse(body).data.token;
    const req2 = http.request({
      hostname: 'localhost',
      port: 8080,
      path: '/api/rooms/5fa1bb81-058e-47ca-814f-79a82e8a6d3b/requests',
      method: 'GET',
      headers: { 'Authorization': 'Bearer ' + token }
    }, res2 => {
      let body2 = '';
      res2.on('data', d => body2 += d);
      res2.on('end', () => console.log('RESPONSE:', body2));
    });
    req2.end();
  });
});
req.write(JSON.stringify({email:'user1@learnex.edu.vn', password:'password123'}));
req.end();
