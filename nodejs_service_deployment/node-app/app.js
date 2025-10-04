const express = require("express");
const app = express();
const PORT = 3000;
const HOST = "0.0.0.0"; // Listen on all interfaces

app.get("/", (req, res) => {
  res.send("Hello from  CI/CD!");
});

app.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});
