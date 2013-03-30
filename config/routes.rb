Rails.application.routes.draw do
  post '/email_processor' => 'griddler/emails#create', as: :email_processor
  get '/email_processor' => 'griddler/emails#check', as: :check_email_processor
end
