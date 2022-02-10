class CreateScrapes < ActiveRecord::Migration[7.0]
  def change
    create_table :scrapes do |t|
      t.string :url, null: false
      t.string :callback_url, null: false
      t.string :callback_id
      t.string :status, null: false, default: "not_started"
      t.string :scrape_type, null: false, default: ENV["DIFFERENTIATE_AS"]

      t.timestamps
    end
  end
end
