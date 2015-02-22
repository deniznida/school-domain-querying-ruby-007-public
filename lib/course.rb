class Course

  ATTRIBUTES = {
    :id => "INTEGER PRIMARY KEY",
    :name => "TEXT",
    :department_id => "INTEGER REFERENCES departments"
  }
  attr_accessor *ATTRIBUTES.keys, :department

  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS courses (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      name TEXT,
      department_id INTEGER
      )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
    DROP TABLE IF EXISTS courses
    SQL
    DB[:conn].execute(sql)
  end   

  def insert
    sql = "INSERT INTO courses (#{ATTRIBUTES.keys[1..-1].join(",")}) VALUES (?,?)"
    DB[:conn].execute(sql, *attribute_values)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM courses")[0][0]
  end

  def attribute_values
    ATTRIBUTES.keys[1..-1].collect{|key| self.send(key)}
  end

  def update
    sql = "UPDATE courses SET #{sql_for_update} WHERE id = ?"
    DB[:conn].execute(sql, *attribute_values, id)
  end    

  def self.new_from_db(row)
    self.new.tap do |s|
      row.each_with_index do |value, index|
        s.send("#{ATTRIBUTES.keys[index]}=", value)
      end
    end
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM courses WHERE name = ?"
      result = DB[:conn].execute(sql,name)[0] #[]    
      self.new_from_db(result) if result
  end

  def self.find_all_by_department_id(department_id)
    sql = "SELECT * FROM courses WHERE department_id = ?"
      result = DB[:conn].execute(sql, department_id)[0] #[]    
      [self.new_from_db(result)] if result
  end

  def sql_for_update
    ATTRIBUTES.keys[1..-1].collect{|k| "#{k} = ?"}.join(",")
  end

  def update
    sql = "UPDATE courses SET #{sql_for_update} WHERE id = ?"
    DB[:conn].execute(sql, *attribute_values, id)
  end  

  def persisted?
    !!self.id
  end

  def save
    persisted? ? update : insert
  end

  def department=(department)
    @department_id = department.id
  end
  
  def department
    Department.find_by_id(self.department_id)
  end
  
  def students
    sql = <<-SQL
    SELECT students.*
    FROM students
    JOIN registrations
    ON students.id = registrations.student_id
    JOIN courses
    ON registrations.course_id = courses.id
    WHERE courses.id = ?
    SQL

    result = DB[:conn].execute(sql, self.id)
    result.map do |row|
      Student.new_from_db(row)
    end
  end

  def add_student(student)
    sql = <<-SQL
    INSERT INTO registrations (course_id, student_id) VALUES (?, ?)
    SQL

    result = DB[:conn].execute(sql, [self.id, student.id])
  end
end
