require 'test_helper'

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get status_show_url
    assert_response :success
  end

end
