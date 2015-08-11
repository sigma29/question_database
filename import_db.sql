CREATE TABLE users(
  id INTEGER PRIMARY KEY,
  fname VARCHAR(25),
  lname VARCHAR(35)
);

CREATE TABLE questions(
  id INTEGER PRIMARY KEY,
  title VARCHAR(30),
  body VARCHAR(255),
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows(
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)

);

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  body VARCHAR(255),
  question_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (author_id) REFERENCES users(id),
  FOREIGN KEY (parent_reply_id)  REFERENCES replies(id)
);

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
  users(fname,lname)
VALUES
  ('Leah','Itagaki'), ('Gina','Jeong');

INSERT INTO
  questions(title, body, author_id)
VALUES
  ('Sample Question', 'What day is today?', (SELECT id FROM users WHERE lname = 'Itagaki')),
  ('Title but no body',NULL, (SELECT id FROM users WHERE lname = 'Jeong'));

INSERT INTO
  question_follows(question_id, user_id)
VALUES
  ((SELECT id FROM questions WHERE title = 'Sample Question'),(SELECT id FROM users WHERE lname = 'Jeong')),
  ((SELECT id FROM questions WHERE title = 'Title but no body'),(SELECT id FROM users WHERE lname = 'Itagaki'));

INSERT INTO
  replies(body, question_id, author_id)
VALUES
  ('Today was raining.',(SELECT id FROM questions WHERE title = 'Sample Question'), (SELECT id FROM users WHERE lname = 'Jeong')),
    ('Where is your question?',(SELECT id FROM questions WHERE title LIKE 'Title%'), (SELECT id FROM users WHERE lname = 'Itagaki'));

INSERT INTO
  replies(body, question_id, parent_reply_id, author_id)
VALUES
  ('Google already asked it for me.',(SELECT id FROM questions WHERE title LIKE 'Title%'), (SELECT id FROM replies WHERE body LIKE '%question?'),(SELECT id FROM users WHERE lname = 'Jeong'));

INSERT INTO
  question_likes(question_id,user_id)
VALUES
  ((SELECT id FROM questions WHERE title LIKE 'Sample%'),(SELECT id FROM users WHERE lname = 'Jeong'));
