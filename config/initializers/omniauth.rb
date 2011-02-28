Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '107180036028128', '185e91e4dad9738c2f68d9ad3c2fac40'
end
