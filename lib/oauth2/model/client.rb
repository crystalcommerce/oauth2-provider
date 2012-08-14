require 'bcrypt'

module OAuth2
  module Model
    
    class Client < ActiveRecord::Base
      OUT_OF_BAND_URI = 'urn:ietf:wg:oauth:2.0:oob'
      self.table_name = :oauth2_clients
      
      belongs_to :oauth2_client_owner, :polymorphic => true
      alias :owner  :oauth2_client_owner
      alias :owner= :oauth2_client_owner=
          
      has_many :authorizations, :class_name => 'OAuth2::Model::Authorization', :dependent => :destroy
      
      validates_uniqueness_of :client_id
      validates_presence_of   :name, :redirect_uri
      after_initialize :set_default_client_type
      validates_inclusion_of :client_type, :in => %w[web_application
                                                     native_application]
      validate :check_format_of_redirect_uri
      
      attr_accessible :name, :redirect_uri, :client_type
      
      before_create :generate_credentials
      before_validation :overwrite_redirect_uri
      
      def self.create_client_id
        OAuth2.generate_id do |client_id|
          count(:conditions => {:client_id => client_id}).zero?
        end
      end
      
      attr_reader :client_secret
      
      def client_secret=(secret)
        @client_secret = secret
        self.client_secret_hash = BCrypt::Password.create(secret)
      end
      
      def valid_client_secret?(secret)
        BCrypt::Password.new(client_secret_hash) == secret
      end

      def native_application?
        client_type == 'native_application'
      end

      def web_application?
        client_type == 'web_application'
      end
      
    private

      def set_default_client_type
        self.client_type ||= 'web_application'
      end
      
      def check_format_of_redirect_uri
        return true if native_application? && redirect_uri == OUT_OF_BAND_URI

        uri = URI.parse(redirect_uri)
        errors.add(:redirect_uri, 'must be an absolute URI') unless uri.absolute?
      rescue
        errors.add(:redirect_uri, 'must be a URI')
      end
      
      def generate_credentials
        self.client_id = self.class.create_client_id
        self.client_secret = OAuth2.random_string
      end

      def overwrite_redirect_uri
        self.redirect_uri = OUT_OF_BAND_URI if native_application?
      end
    end
    
  end
end

