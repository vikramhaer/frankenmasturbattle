AdminData.config do |config|
  config.number_of_records_per_page = 50
end

AdminData.config do |config|
  config.is_allowed_to_view = lambda {|controller| controller.send('is_admin?') }
  config.is_allowed_to_update = lambda {|controller| controller.send('is_admin?') }
end
