class CreateOpens < ActiveRecord::Migration[4.2]
  def self.up
    create_table :opens do |t|
      t.string :url
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :opens
  end
end
