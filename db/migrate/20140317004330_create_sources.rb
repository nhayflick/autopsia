class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :title
      t.integer :author_id
      t.integer :isbn
      t.string :google_id

      t.timestamps
    end
  end
end
