class CreateSnippets < ActiveRecord::Migration
  def change
    create_table :snippets do |t|
      t.text :body
      t.integer :word_id
      t.integer :source_id
      t.integer :definition_id

      t.timestamps
    end
  end
end
