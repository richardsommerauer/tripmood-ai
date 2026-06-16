class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.references :user, null: false, foreign_key: true
      t.string :city
      t.string :duration
      t.string :budget
      t.string :mood
      t.string :energy
      t.string :travel_style
      t.string :interests, array: true, default: []
      t.string :title
      t.text :summary
      t.jsonb :plan, default: {}

      t.timestamps
    end
  end
end
