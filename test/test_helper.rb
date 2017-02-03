ENV["RAILS_ENV"] = "test"

require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/around'
require 'rails'
require 'action_controller'
require 'rails/generators'

class FakeApplication < Rails::Application; end

Rails.application = FakeApplication
Rails.configuration.action_controller = ActiveSupport::OrderedOptions.new
Rails.configuration.secret_key_base = 'secret_key_base'

ActiveSupport.test_order = :random if ActiveSupport.respond_to?(:test_order=)

require 'action_pack'
require 'strong_parameters' if ActionPack::VERSION::MAJOR == 3

module ActionController
  SharedTestRoutes = ActionDispatch::Routing::RouteSet.new
  SharedTestRoutes.draw do
    get ':controller(/:action)'
    post ':controller(/:action)'
    put ':controller(/:action)'
    delete ':controller(/:action)'
  end

  class Base
    include ActionController::Testing
    include SharedTestRoutes.url_helpers

    rescue_from(ActionController::ParameterMissing) do |e|
      render (ActiveSupport::VERSION::MAJOR < 5 ? :text : :plain) => "Required parameter missing: #{e.param}", :status => :bad_request
    end
  end

  class ActionController::TestCase
    setup do
      @routes = SharedTestRoutes
    end
  end
end

require 'stronger_parameters'
require 'minitest/rails'
require 'minitest/autorun'

class MiniTest::Spec
  def params(hash)
    ActionController::Parameters.new(hash)
  end

  def assert_rejects(key, &block)
    err = block.must_raise StrongerParameters::InvalidParameter
    err.key.must_equal key.to_s
  end

  def self.permits(value, options = {})
    type_casted = options.fetch(:as, value)

    it "permits #{value.inspect} as #{type_casted.inspect}" do
      permitted = params(:value => value).permit(:value => subject)
      permitted = permitted.to_h if Rails::VERSION::MAJOR >= 5
      if defined?(assert_nil) && type_casted.nil?
        assert_nil permitted[:value]
      else
        permitted[:value].must_equal type_casted
      end
    end
  end

  def self.rejects(value, options = {})
    key = options.fetch(:key, :value)

    it "rejects #{value.inspect}" do
      assert_rejects(key) { params(:value => value).permit(:value => subject) }
    end
  end
end
