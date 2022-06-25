class CreateRepositories < ActiveRecord::Migration[6.1]
  def change
    create_table :repositories do |t|
      t.string :full_name
      t.string :language
      t.string :link
      t.string :name

      t.timestamps
    end
  end
end
