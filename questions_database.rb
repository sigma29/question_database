require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true
    self.type_translation = true
  end

end

class Question
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
       questions.id = (?)
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.find_by_author_id(author_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.author_id = (?)
    SQL

    results.map! { |result| Question.new(result) }
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  attr_accessor :id, :title, :body, :author_id

  def initialize(opts = {})
    @id = opts["id"]
    @title = opts["title"]
    @body = opts["body"]
    @author_id = opts["author_id"]
  end

  def author
    User.find_by_id(author_id)
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollow.followers_for_question_id(id)
  end

end

class User
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
       users.id = (?)
    SQL
    results.map { |result| User.new(result) }
  end

  def self.find_by_name(fname, lname)
    results = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
       users.fname = (?) AND users.lname = (?)
    SQL
    results.map { |result| User.new(result) }
  end

  attr_accessor :id, :fname, :lname

  def initialize(opts = {})
    @id = opts["id"]
    @fname = opts["fname"]
    @lname = opts["lname"]
  end

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_user_id(id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(id)
  end

end

class Reply
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
       replies.id = (?)
    SQL
    results.map { |result| Reply.new(result) }
  end

  def self.find_by_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
       replies.author_id = (?)
    SQL
    results.map { |result| Reply.new(result) }
  end

  def self.find_by_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
       replies.question_id = (?)
    SQL
    results.map { |result| Reply.new(result) }
  end

  attr_accessor :id, :body, :question_id, :parent_reply_id, :author_id

  def initialize(opts = {})
    @id = opts["id"]
    @body = opts["body"]
    @question_id = opts["question_id"]
    @parent_reply_id = opts["parent_reply_id"]
    @author_id = opts["author_id"]
  end

  def author
    User.find_by_id(author_id)
  end

  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    Reply.find_by_id(parent_reply_id)
  end

  def child_replies
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
       replies.parent_reply_id = (?)
    SQL

    results.map{|result| Reply.new(result)}
  end

end

class QuestionFollow
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        question_follows.id = (?)
    SQL
    results.map { |result| QuestionFollow.new(result) }
  end

  def self.followers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id,
        users.fname,
        users.lname
      FROM
        question_follows
      JOIN
        users on question_follows.user_id = users.id
      WHERE
        question_follows.question_id = (?)
    SQL

    results.map { |result| User.new(result) }
  end

  def self.followed_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id,
        questions.title,
        questions.body,
        questions.author_id
      FROM
        question_follows
      JOIN
        questions on question_follows.question_id = questions.id
      WHERE
        question_follows.user_id = (?)
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.most_followed_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL )
      SELECT
        questions.id,
        questions.title,
        questions.body,
        questions.author_id
      FROM
        question_follows
      JOIN
        questions
      ON
        questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.id) DESC
      LIMIT #{n}
    SQL
    results.map { |result| Question.new(result) }
  end


  attr_accessor :id, :question_id, :user_id

  def initialize(opts = {})
    @id = opts["id"]
    @question_id = opts["question_id"]
    @user_id = opts["user_id"]
  end
end

class QuestionLike
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        question_likes.id = (?)
    SQL

    results.map { |result| QuestionLike.new(result) }

  end

  def self.likers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id,
        users.fname,
        users.lname
      FROM
        question_likes
      JOIN
        users
      ON
        users.id = question_likes.user_id
      WHERE
        question_likes.question_id = (?)
    SQL

    results.map { |result| User.new(result) }

  end

  def self.num_likes_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(id) AS like_count
      FROM
        question_likes
      WHERE
        question_likes.question_id = (?)
    SQL

    results.first['like_count']
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id,
        questions.title,
        questions.body,
        questions.author_id
      FROM
        question_likes
      JOIN
        questions
      ON
        question_likes.question_id = questions.id
      WHERE
        question_likes.user_id = (?)
    SQL
     p results
    results.map { |result| Question.new(result) }
  end

  attr_accessor :id, :question_id, :user_id

  def initialize(opts = {})
    @id = opts["id"]
    @question_id = opts["question_id"]
    @user_id = opts["user_id"]
  end
end

if __FILE__ == $PROGRAM_NAME
  q = Question.find_by_id(1)
  p q
  # r = Reply.find_by_question_id(2)
  # p r
  u = User.find_by_name('Leah', 'Itagaki')
  p u.first
   q = u.first.authored_questions
   p q
   r = u.first.authored_replies
   p r
  p  q.first.replies
  # question = r.first.question
  # p question
  # reply = Reply.find_by_id(2)
  # p reply.first.child_replies
  # p QuestionFollow.followed_questions_for_user_id(1)
  p u.first.followed_questions
  p q.first.followers

  p Question.most_followed(2)
  p QuestionLike.likers_for_question_id(1)
  p QuestionLike.num_likes_for_question_id(1)
  p QuestionLike.liked_questions_for_user_id(2)


end
