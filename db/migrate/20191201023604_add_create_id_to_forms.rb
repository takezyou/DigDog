class AddCreateIdToForms < ActiveRecord::Migration[5.2]
  def change
    add_column :forms, :create_id, :integer
    add_column :forms, :image, :string
  end
end
