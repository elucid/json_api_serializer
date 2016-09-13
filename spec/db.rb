require 'active_record'
require 'database_cleaner'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

ActiveRecord::Schema.define do
  create_table :authors do |t|
    t.string :name
    t.string :email

    t.timestamps
  end

  create_table :posts do |t|
    t.string :title
    t.text :body
    t.integer :author_id

    t.timestamps
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:transaction)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
