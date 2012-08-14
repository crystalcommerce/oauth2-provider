module OAuth2
  module Model
    
    class BaseSchema < ActiveRecord::Migration
      def change
        create_table :oauth2_clients, :force => true do |t|
          t.timestamps
          t.string     :oauth2_client_owner_type
          t.integer    :oauth2_client_owner_id
          t.string     :name
          t.string     :client_id
          t.string     :client_secret_hash
          t.string     :redirect_uri
        end
        add_index :oauth2_clients, :client_id
        
        create_table :oauth2_authorizations, :force => true do |t|
          t.timestamps
          t.string     :oauth2_resource_owner_type
          t.integer    :oauth2_resource_owner_id
          t.belongs_to :client
          t.string     :scope
          t.string     :code,               :limit => 40
          t.string     :access_token_hash,  :limit => 40
          t.string     :refresh_token_hash, :limit => 40
          t.datetime   :expires_at
        end
        add_index :oauth2_authorizations, [:client_id, :code]
        add_index :oauth2_authorizations, [:access_token_hash]
        add_index :oauth2_authorizations, [:client_id, :access_token_hash]
        add_index :oauth2_authorizations, [:client_id, :refresh_token_hash]
      end
    end

    class ClientTypeMigration < ActiveRecord::Migration
      def change
        add_column :oauth2_clients, :client_type, :string,
                   :default => 'web_application'
      end
    end

    class Schema
      MIGRATIONS = [BaseSchema, ClientTypeMigration]

      def self.up
        MIGRATIONS.each {|m| m.migrate(:up)}
      end

      def self.down
        MIGRATIONS.reverse.each {|m| m.migrate(:down)}
      end
    end
  end
end
