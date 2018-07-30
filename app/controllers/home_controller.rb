class HomeController < ApplicationController
  before_action :check_user_log_in

  def index
    @teachers = Teacher.select(:signature_id).where(:user_id => current_user.id)

    @signatures = []
    @teachers.each do |s|
      @signatures.append(s.signature_id)
    end
  end

  private

    def check_user_log_in
      if not user_signed_in?
        redirect_to(user_session_path)
      end
    end
end