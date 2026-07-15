const express = require('express');
const mysql = require('mysql2');
const cors = require('cors'); // 1. CORS पॅकेज इम्पोर्ट केलं
const app = express();
const PORT = 5000;

// 2. CORS
app.use(cors());
app.use(express.json());

// MySQL Database Connection Configuration
const db = mysql.createConnection({
    host: '10.0.3.60', // DB private IP
    user: 'employee_user',
    password: 'EmployeePassword123',
    database: 'employee_db',
    port: 3306
});

// Connect to Database
db.connect(err => {
    if (err) {
        console.error('Database connection failed: ' + err.stack);
        return;
    }
    console.log('Connected to MySQL Database.');
});

// API Endpoint to fetch data
app.get('/employees', (req, res) => {
    db.query('SELECT * FROM employees', (err, results) => {
        if (err) {
            res.status(500).send(err);
        } else {
            res.json(results);
        }
    });
});

app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});
