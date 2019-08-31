require 'test_helper'

class CreateControllerTest < ActionDispatch::IntegrationTest
  test "should get pods" do
    get create_pods_url
    assert_response :success
  end

end
