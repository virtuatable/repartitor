ENV['RACK_ENV'] = 'test'

require 'bundler'
Bundler.require :test

require 'arkaan/specs'

service = Arkaan::Utils::MicroService.instance
  .register_as('websockets')
  .from_location(__FILE__)
  .in_test_mode

Arkaan::Monitoring::Websocket.find_or_create_by(url: 'ws://test-websocket.com').save

Arkaan::Specs.include_shared_examples