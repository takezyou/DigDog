class ApplicationController < ActionController::Base

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end

  #404 Not Foundを表示させる
  def render_404
    render file: "#{Rails.root}/public/404.html", status: 404
  end
end
