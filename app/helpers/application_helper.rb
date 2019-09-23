module ApplicationHelper

  def page_title
    title = "DigDog"
    title = @page_title if @page_title
    title
  end
end
