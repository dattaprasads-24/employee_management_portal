const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// atabase Private IP टा
const db = mysql.createConnection({
    host: '10.0.3.60',
    user: 'employee_user',
    password: 'EmployeePassword123',
    database: 'employee_db',
    port: 3306
});

// Database Connection Test
db.connect((err) => {
    if (err) {
        console.error('Database connection failed: ' + err.stack);
        return;
    }
    console.log('Connected to MySQL Database.');
});

// GET Endpoin - सर्व t
app.get('/api/employees', (req, res) => {
    db.query('SELECT * FROM employees', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
});

// POST Endpoint - न
app.post('/api/employees', (req, res) => {
    const { name, role } = req.body;
    db.query('INSERT INTO employees (name, role) VALUES (?, ?)', [name, role], (err, result) => {
        if (err) return res.status(500).send(err);
        res.status(201).json({ id: result.insertId, name, role });
    });
});

const PORT = 5000;
app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});
