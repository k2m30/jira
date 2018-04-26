class CreateSnapshots < ActiveRecord::Migration[5.1]
  def change
    create_table :snapshots do |t|
      t.date :date
      t.text :table
      t.belongs_to :project
    end
  end
end
