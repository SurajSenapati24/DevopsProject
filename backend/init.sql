CREATE DATABASE IF NOT EXISTS profile_db;

CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'apppassword';
GRANT ALL PRIVILEGES ON profile_db.* TO 'appuser'@'%';
FLUSH PRIVILEGES;

USE profile_db;

CREATE TABLE IF NOT EXISTS profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  age INT NOT NULL,
  profession VARCHAR(100) NOT NULL
);

INSERT INTO profiles (name, age, profession) VALUES
  ('Alice', 30, 'Software Engineer'),
  ('Bob', 40, 'Teacher');
