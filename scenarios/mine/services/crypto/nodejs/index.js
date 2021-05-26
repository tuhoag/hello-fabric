const express = require('express');
const app = express();
const port = process.env.API_PORT;

app.get('/test', (req, res) => {
    res.send("Hello World");
});

app.listen(port, () => {
    console.log(`Start listening on port: ${port}`);
});
