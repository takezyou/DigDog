class CreateCreates < ActiveRecord::Migration[5.2]
  def change
    create_table :creates do |t|
      t.string :deploy
      t.string :space
      t.timestamp :create_time
      t.boolean :is_delete
      t.boolean :is_recognize

      t.timestamps
    end
  end
end
