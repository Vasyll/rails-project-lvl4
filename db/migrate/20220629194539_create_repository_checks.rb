class CreateRepositoryChecks < ActiveRecord::Migration[6.1]
  def change
    create_table :repository_checks do |t|
      t.string :state
      t.string :reference
      t.string :check_passed
      t.references :repository, null: false, foreign_key: true

      t.timestamps
    end
  end
end
