class AddCanonicalEmailToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :users, :canonical_email, :string

    transaction do
      User.find_each do |user|
        user.update_attribute(:canonical_email, EmailAddress.canonical(user.email))
      end
    end
    add_index :users, :canonical_email, algorithm: :concurrently
  end
end
