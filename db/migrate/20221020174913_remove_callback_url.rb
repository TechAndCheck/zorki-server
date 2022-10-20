class RemoveCallbackUrl < ActiveRecord::Migration[7.0]
  def change
    remove_column :scrapes, :callback_url, :string, null: false
  end
end
