require 'test_helper'

class UidTest < StrategyTestCase
  def setup
    super
    strategy.stubs(:raw_info).returns({ 'objectId' => '123' })
  end

  def test_return_id_from_raw_info
    assert_equal '123', strategy.uid
  end
end
