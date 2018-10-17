require 'test_helper'

class UidTest < StrategyTestCase
  def setup
    super
    strategy.stubs(:raw_info).returns({ 'id' => '123' })
  end

  def test_return_id_from_raw_info
    assert_equal '123', strategy.uid
  end
end

class AccessTokenTest < StrategyTestCase
  def setup
    super
    @request.stubs(:params).returns({ 'access_token' => 'valid_access_token' })
    strategy.stubs(:client).returns(:client)
  end

  def test_build_access_token
    token = strategy.build_access_token
    assert_equal token.token, 'valid_access_token'
    assert_equal token.client, :client
  end
end