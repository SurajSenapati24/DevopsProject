const express = require('express');
const path = require('path');
const mysql = require('mysql2');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;

// Static HTML directory
app.use(express.static(__dirname));

// Parsing form data
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

//app.use(bodyParser.urlencoded({ extended: true }));


// MySQL Connection
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_USER = process.env.DB_USER || 'appuser';
const DB_PASS = process.env.DB_PASS || 'apppassword';
const DB_NAME = process.env.DB_NAME || 'profile_db';

const db = mysql.createConnection({
  host: DB_HOST,
  user: DB_USER,
  password: DB_PASS,
  database: DB_NAME
});

db.connect((err) => {
  if (err) {
    console.error('DB Connection Failed:', err);
  } else {
    console.log('MySQL Connected');
    db.query(`CREATE TABLE IF NOT EXISTS profiles (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      age INT NOT NULL,
      profession VARCHAR(100) NOT NULL
    )`);
  }
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.post('/submit', (req, res) => {
  const { name, age, profession } = req.body;
  if (!name || !age || !profession) {
    return res.status(400).send('<p>All fields are required. <a href="/">Go back</a></p>');
  }

  db.query('INSERT INTO profiles (name, age, profession) VALUES (?, ?, ?)',
    [name, age, profession], (err, result) => {
      if (err) {
        return res.status(500).send('Database error');
      }
      res.send(`
        <h2>Profile Saved!</h2>
        <p>ID: ${result.insertId}</p>
        <p>Name: ${name}</p>
        <p>Age: ${age}</p>
        <p>Profession: ${profession}</p>
        <a href="/">Add another</a>
      `);
    });
});

app.get('/health', (req, res) => {
  db.ping((err) => {
    if (err) return res.status(500).json({ status: "unhealthy" });
    res.json({ status: "healthy" });
  });
});

app.listen(PORT, () => {
  console.log(`App running on port ${PORT}`);
});
