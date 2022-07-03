class AddFieldToRepository < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :clone_url, :string
  end
end
