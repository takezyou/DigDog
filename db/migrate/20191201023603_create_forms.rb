class CreateForms < ActiveRecord::Migration[5.2]
  def change
    create_table :forms do |t|
      t.timestamps null: false
    end
  end
end
