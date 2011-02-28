Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '107180036028128', '185e91e4dad9738c2f68d9ad3c2fac40', {:scope => 'publish_stream,email,friends_education_history,friends_location,friends_work_history', :display => "popup"}
end
