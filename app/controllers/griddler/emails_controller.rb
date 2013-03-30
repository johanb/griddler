class Griddler::EmailsController < ActionController::Base
  def create
    Griddler::Email.process(normalized_params)
    head :ok
  end

  def check
    head :ok
  end

  private

  def normalized_params
    Griddler.configuration.email_service.normalize_params(params)
  end
end
