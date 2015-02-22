require 'sqlite3'
require_relative '../lib/student'
require_relative '../lib/department'
require_relative '../lib/course'
require_relative '../lib/registration'
require "pry"

DB = {:conn => SQLite3::Database.new("db/school.db")}
