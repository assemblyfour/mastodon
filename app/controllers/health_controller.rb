class HealthController < ActionController::Base
  def check
    render json: {status: 'ok'}
  end
end
