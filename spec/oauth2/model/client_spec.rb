require 'spec_helper'

describe OAuth2::Model::Client do
  before do
    @client = OAuth2::Model::Client.create(:name => 'App', :redirect_uri => 'http://example.com/cb')
    @owner  = Factory(:owner)
    Factory(:authorization, :client => @client, :owner => @owner)
  end
  
  it "is valid" do
    @client.should be_valid
  end
  
  it "is invalid without a name" do
    @client.name = nil
    @client.should_not be_valid
  end
  
  it "is invalid without a redirect_uri" do
    @client.redirect_uri = nil
    @client.should_not be_valid
  end
  
  it "is invalid with a non-URI redirect_uri" do
    @client.redirect_uri = 'foo'
    @client.should_not be_valid
  end
  
  # http://en.wikipedia.org/wiki/HTTP_response_splitting
  it "is invalid if the URI contains HTTP line breaks" do
    @client.redirect_uri = "http://example.com/c\r\nb"
    @client.should_not be_valid
  end
  
  it "cannot mass-assign client_id" do
    @client.update_attributes(:client_id => 'foo')
    @client.client_id.should_not == 'foo'
  end
  
  it "cannot mass-assign client_secret" do
    @client.update_attributes(:client_secret => 'foo')
    @client.client_secret.should_not == 'foo'
  end
  
  it "has client_id and client_secret filled in" do
    @client.client_id.should_not be_nil
    @client.client_secret.should_not be_nil
  end
  
  it "destroys its authorizations on destroy" do
    @client.destroy
    OAuth2::Model::Authorization.count.should be_zero
  end

  it "defaults the client type to web_application" do
    @client.client_type.should == 'web_application'
    @client.web_application?.should be_true
  end

  it "allows mass-assignment of client_type" do
    @client.update_attributes(:client_type => 'native_application')
    @client.client_type.should == 'native_application'
  end

  it "does not identify as a native_application" do
    @client.native_application?.should be_false
  end

  context "native application" do
    before do
      @client.client_type = 'native_application'
    end

    it "changes the redirect uri to out of band" do
      @client.save
      @client.redirect_uri.should == 'urn:ietf:wg:oauth:2.0:oob'
    end

    it "is valid" do
      @client.should be_valid
    end

    it "identifies as a native_application" do
      @client.native_application?.should be_true
    end
  end

  context "bogus client type" do
    before do
      @client.client_type = 'porkchop_sandwiches'
    end

    it "is not valid" do
      @client.should_not be_valid
    end
  end
end

