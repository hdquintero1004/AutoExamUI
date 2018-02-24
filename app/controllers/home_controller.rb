class HomeController < ApplicationController
  def index
    if not user_signed_in?
      redirect_to(user_session_path)
    else
      @teachers = Teacher.select(:signature_id).where(:user_id => current_user.id)

      @signatures = []
      @teachers.each do |s|
        @signatures.append(s.signature_id)
      end
    end
  end
end