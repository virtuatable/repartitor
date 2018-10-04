require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

$stdout.sync = true

service = Arkaan::Utils::MicroService.instance
  .register_as('repartitor')
  .from_location(__FILE__)
  .in_standard_mode

puts Arkaan::Utils::MicroService.instance.instance.url

map(service.path) { run Controllers::Repartitor.new }

at_exit { Arkaan::Utils::MicroService.instance.deactivate! }