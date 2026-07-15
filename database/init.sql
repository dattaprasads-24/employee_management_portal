CREATE DATABASE IF NOT EXISTS employee_db;
USE employee_db;

CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL
);

INSERT INTO employees (name, role) VALUES 
('Soham S', 'DevOps Engineer'),
('ABC', 'Full Stack Developer');

CREATE USER IF NOT EXISTS 'employee_user'@'%' IDENTIFIED BY 'EmployeePassword123';
GRANT ALL PRIVILEGES ON employee_db.* TO 'employee_user'@'%';
FLUSH PRIVILEGES;
