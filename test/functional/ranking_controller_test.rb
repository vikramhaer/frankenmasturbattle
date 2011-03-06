require 'test_helper'

class RankingControllerTest < ActionController::TestCase
  test "should get global" do
    get :global
    assert_response :success
  end

  test "should get friends" do
    get :friends
    assert_response :success
  end

  test "should get group" do
    get :group
    assert_response :success
  end

end
