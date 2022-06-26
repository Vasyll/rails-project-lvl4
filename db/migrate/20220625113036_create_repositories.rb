class CreateRepositories < ActiveRecord::Migration[6.1]
  def change
    create_table :repositories do |t|
      t.string :full_name
      t.integer :github_id
      t.string :language
      t.string :link
      t.string :name
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
