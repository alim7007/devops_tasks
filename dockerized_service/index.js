import express from "express";
import auth from "basic-auth";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const HOST = "0.0.0.0"; // Listen on all interfaces
const PORT = process.env.PORT || 3000;
const { USERNAME, PASSWORD, SECRET_MESSAGE } = process.env;

if (!USERNAME || !PASSWORD || !SECRET_MESSAGE) {
  console.error(
    "Missing required env vars. Ensure USERNAME, PASSWORD, and SECRET_MESSAGE are set in .env"
  );
  process.exit(1);
}

// Simple home route
app.get("/", (_req, res) => {
  res.type("text/plain").send("Hello, world!");
});

// Basic Auth middleware
function requireBasicAuth(req, res, next) {
  const credentials = auth(req);

  const isValid =
    credentials &&
    credentials.name === USERNAME &&
    credentials.pass === PASSWORD;

  if (!isValid) {
    // Prompt browser with Basic Auth dialog
    res.set("WWW-Authenticate", 'Basic realm="Restricted", charset="UTF-8"');
    return res
      .status(401)
      .json({ error: "Unauthorized: invalid username or password." });
  }

  next();
}

// Protected route
app.get("/secret", requireBasicAuth, (_req, res) => {
  res.json({ message: SECRET_MESSAGE });
});

app.use((req, res) => {
  res.status(404).json({ error: "Not found" });
});

app.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});


