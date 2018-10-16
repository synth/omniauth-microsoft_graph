require 'bundler/setup'
require 'minitest/autorun'
require 'mocha/setup'
require 'omniauth/strategies/microsoft_graph'

OmniAuth.config.test_mode = true

class StrategyTestCase < Minitest::Test
  def setup
    @request = stub('Request')
    @request.stubs(:params).returns({})
    @request.stubs(:cookies).returns({})
    @request.stubs(:env).returns({})
    @request.stubs(:scheme).returns({})
    @request.stubs(:ssl?).returns(false)

    @client_id = '123'
    @client_secret = '53cr3tz'
    @options = {}
  end

  def strategy
    @strategy ||= begin
      args = [@client_id, @client_secret, @options].compact
      OmniAuth::Strategies::MicrosoftGraph.new(nil, *args).tap do |strategy|
        strategy.stubs(:request).returns(@request)
      end
    end
  end
end

