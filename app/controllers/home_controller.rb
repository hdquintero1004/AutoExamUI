class HomeController < ApplicationController
  def index
    if not user_signed_in?
      redirect_to(user_session_path)
    else
      @signatures = Teacher.select(:signature_id).where(user_id: current_user.id)
    end
  end
end
