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

class TableModel
  TABLES_HASH = {
    :Question => "questions",
    :User => "users",
    :Reply => "replies",
    :QuestionLike => "question_likes",
    :QuestionFollow => "question_follows"
    }
  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{TABLES_HASH[self.to_s.to_sym]}
      WHERE
        #{TABLES_HASH[self.to_s.to_sym]}.id = (?)
    SQL


    results.map { |result| self.new(result) }
  end
end

class Question < TableModel

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

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
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

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end

  def save
    if id.nil?
     QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id)
       INSERT INTO
        questions(title, body, author_id)
       VALUES
        (?,?,?)
       SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL,title, body, author_id, id)
       UPDATE
         questions
       SET
         title = (?),
         body = (?),
         author_id = (?)
       WHERE
         id = (?)
       SQL
    end
  end


end

class User < TableModel

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

  def liked_questions
    QuestionLike.liked_questions_for_user_id(id)
  end

  def average_karma
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        CAST(COUNT(question_likes.id) AS FLOAT) / COUNT(questions.id) AS avg_likes_per_question
      FROM
        questions
      LEFT OUTER JOIN
        question_likes
      ON
        questions.id = question_likes.question_id
      WHERE
       questions.author_id = (?)
      GROUP BY
        questions.id
    SQL

    results.first['avg_likes_per_question']
  end

  def save
    if id.nil?
     QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
       INSERT INTO
        users(fname, lname)
       VALUES
        (?,?)
       SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL,fname, lname, id)
       UPDATE
         users
       SET
         fname = (?),
         lname = (?)
       WHERE
         id = (?)
       SQL
    end
  end
end

class Reply < TableModel

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

    results.map { |result| Reply.new(result) }
  end

  def save
    if id.nil?
     QuestionsDatabase.instance.execute(<<-SQL, body, question_id,parent_reply_id,author_id)
       INSERT INTO
        replies(body, question_id,parent_reply_id,author_id)
       VALUES
        (?,?,?,?)
       SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, body, question_id,parent_reply_id,author_id, id)
        UPDATE
          replies
        SET
          body = (?),
          question_id = (?),
          parent_reply_id = (?),
          author_id = (?)
        WHERE
          id = (?)
      SQL
    end
  end

end

class QuestionFollow < TableModel

  def self.followers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
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
        questions.*
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
    results = QuestionsDatabase.instance.execute(<<-SQL ,n)
      SELECT
        questions.*
      FROM
        questions
      LEFT OUTER JOIN
        question_follows
      ON
        questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.id) DESC
      LIMIT (?)
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

class QuestionLike < TableModel

  def self.likers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
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
        COUNT(question_likes.id) AS like_count
      FROM
        questions
      LEFT OUTER JOIN
        question_likes
      ON
        question_likes.question_id = questions.id
      WHERE
        question_likes.question_id = (?)
    SQL

    results.first['like_count']
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        question_likes
      JOIN
        questions
      ON
        question_likes.question_id = questions.id
      WHERE
        question_likes.user_id = (?)
    SQL

    results.map { |result| Question.new(result) }
  end

  def self.most_liked_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL,n)
      SELECT
        questions.*
      FROM
        questions
      LEFT OUTER JOIN
        question_likes
      ON
        question_likes.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_likes.id) DESC
      LIMIT
      (?)

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

if __FILE__ == $PROGRAM_NAME


  #p User.find_by_id(1)
  # saveuser = User.new
  # saveuser.fname = 'Breakfast'
  # saveuser.lname= "at Tiffany's"
  # saveuser.save
  #
  # id = User.find_by_name('Breakfast',"at Tiffany's").first.id
  # p id
  # saveuser.lname = 'Club'
  # saveuser.save
  # p User.find_by_id(id)
  savereply = Reply.new
  savereply.body = "Please save me"
  savereply.question_id = 2
  savereply.author_id = 1

  reply_id = savereply.save
  p savereply

  savereply.body = "I haz been saved?"
  savereply.save
  p Reply.find_by_id(1)



end
