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
