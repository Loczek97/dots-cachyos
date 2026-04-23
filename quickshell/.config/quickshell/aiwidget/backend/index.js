const express = require("express");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const fs = require("fs");
const cors = require("cors");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());

const CONFIG_PATH = path.join(__dirname, "history.json");
const PERSONAS = require("./personas.json");

const genAI = new GoogleGenerativeAI(
  process.env.GEMINI_API_KEY || "AIzaSyAyxI1z70ubckSmMG9-WymdSO3tzqUqZ9I",
);

let currentHistory = [];
let currentPersona = PERSONAS[0];

app.get("/personas", (req, res) => res.json(PERSONAS));

app.post("/set_persona", (req, res) => {
  const { id } = req.body;
  currentPersona = PERSONAS.find((p) => p.id === id) || PERSONAS[0];
  currentHistory = [];
  res.json({ status: "ok", persona: currentPersona.name });
});

app.post("/chat", async (req, res) => {
  const { message } = req.body;
  try {
      const model = genAI.getGenerativeModel({ 
          model: "gemini-3-flash",
          systemInstruction: currentPersona.systemPrompt 
      });

    const chat = model.startChat({
      history: currentHistory,
    });

    const result = await chat.sendMessage(message);
    const responseText = result.response.text();

    const bashMatch = responseText.match(/\[BASH:\s*(.*?)\]/);
    const command = bashMatch ? bashMatch[1] : null;

    currentHistory.push({ role: "user", parts: [{ text: message }] });
    currentHistory.push({ role: "model", parts: [{ text: responseText }] });

    res.json({
      text: responseText.replace(/\[BASH:.*?\]/g, "").trim(),
      command: command,
    });

    fs.writeFileSync(CONFIG_PATH, JSON.stringify(currentHistory));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Błąd Gemini API" });
  }
});

app.post("/reset", (req, res) => {
  currentHistory = [];
  res.json({ status: "reset" });
});

app.listen(1337, () => console.log("AiWidget Backend na porcie 1337"));
