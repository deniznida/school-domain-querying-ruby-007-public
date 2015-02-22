class Department

  ATTRIBUTES = {
    :id => "INTEGER PRIMARY KEY",
    :name => "TEXT"
  }
  attr_accessor *ATTRIBUTES.keys
  
  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS departments (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      name TEXT
      )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
    DROP TABLE IF EXISTS departments
    SQL
    DB[:conn].execute(sql)
  end   

  def insert
    sql = "INSERT INTO departments (name) VALUES (?)"
    DB[:conn].execute(sql, name)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM departments")[0][0]
  end

  def self.new_from_db(row)
    self.new.tap do |s|
      row.each_with_index do |value, index|
          s.send("#{ATTRIBUTES.keys[index]}=", value)
      end
    end
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM departments WHERE name=?"
    result = DB[:conn].execute(sql, name)[0] 
    self.new_from_db(result) if result
  end

  def self.find_by_id(id)
    sql = "SELECT * FROM departments WHERE id = ?"
      result = DB[:conn].execute(sql, id)[0] #[]    
      self.new_from_db(result) if result
  end

  def attribute_values
    ATTRIBUTES.keys[1..-1].collect{|key| self.send(key)}
  end

  def sql_for_update
    ATTRIBUTES.keys[1..-1].collect{|k| "#{k} = ?"}.join(",")
  end

  def update
    sql = "UPDATE departments SET #{sql_for_update} WHERE id = ?"
    DB[:conn].execute(sql, *attribute_values, id)
  end  

  def persisted?
    !!self.id
  end

  def save
    persisted? ? update : insert
  end

  def name=(name)
    @name = name
    update
  end

  def courses
    sql = <<-SQL
    SELECT courses.*
    FROM courses
    JOIN departments
    ON courses.department_id = departments.id
    WHERE departments.id = ?
    SQL

    result = DB[:conn].execute(sql, self.id)
    result.map do |row|
      Course.new_from_db(row)
    end
  end

  def add_course(course)
    sql = <<-SQL
    INSERT INTO courses (name, department_id)
    VALUES (?, ?)
    SQL
    
    DB[:conn].execute(sql, [course.name, self.id])
  end 
end