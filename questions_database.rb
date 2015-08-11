require 'sqlite3'
require 'singleton'

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
       question.id = (?)
    SQL
    results.map { |result| Question.new(result) }
  end

  attr_accessor :id, :title, :body, :author_id

  def initialize(opts = {})
    @id = opts[id]
    @title = opts[title]
    @body = opts[body]
    @author_id = opts[author_id]
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

  attr_accessor :id, :fname, :lname

  def initialize(opts = {})
    @id = opts[id]
    @fname = opts[fname]
    @lname = opts[lname]
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

  attr_accessor :id, :body, :question_id, :parent_reply_id, :author_id

  def initialize(opts = {})
    @id = opts[id]
    @body = opts[body]
    @question_id = opts[question_id]
    @parent_reply_id = opts[parent_reply_id]
    @author_id = opts[author_id]
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

  attr_accessor :id, :question_id, :user_id

  def initialize(opts = {})
    @id = opts[id]
    @question_id = opts[question_id]
    @user_id = opts[user_id]
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

  attr_accessor :id, :question_id, :user_id

  def initialize(opts = {})
    @id = opts[id]
    @question_id = opts[question_id]
    @user_id = opts[user_id]
  end
end
