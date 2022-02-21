class RemoveDefaultTypeOfScrape < ActiveRecord::Migration[7.0]
  def up
    change_column :scrapes, :scrape_type, :string, null: true, default: nil
  end

  def down
    change_column :scrapes, :scrape_type, :string, null: false, default: ENV["DIFFERENTIATE_AS"]
  end
end
