class AddSuspensionDataToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :suspended_until, :datetime
    add_column :accounts, :suspension_reason, :text
  end
end
