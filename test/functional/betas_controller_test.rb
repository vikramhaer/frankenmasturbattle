require 'test_helper'

class BetasControllerTest < ActionController::TestCase
  setup do
    @beta = betas(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:betas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create beta" do
    assert_difference('Beta.count') do
      post :create, :beta => @beta.attributes
    end

    assert_redirected_to beta_path(assigns(:beta))
  end

  test "should show beta" do
    get :show, :id => @beta.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @beta.to_param
    assert_response :success
  end

  test "should update beta" do
    put :update, :id => @beta.to_param, :beta => @beta.attributes
    assert_redirected_to beta_path(assigns(:beta))
  end

  test "should destroy beta" do
    assert_difference('Beta.count', -1) do
      delete :destroy, :id => @beta.to_param
    end

    assert_redirected_to betas_path
  end
end
