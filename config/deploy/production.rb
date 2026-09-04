# config/deploy/production.rb
require 'dotenv'
Dotenv.load(File.expand_path('../../.env', __dir__))

server ENV['PRODUCTION_SERVER'], user: ENV['PRODUCTION_USER'], roles: %w{web app laravel composer}
set :deploy_to, ENV['PRODUCTION_DEPLOY_TO']
set :laravel_dotenv_file, ENV['PRODUCTION_DOTENV']
set :ssh_options, {
    keys: [ENV['PRODUCTION_SSH_KEY']],
    forward_agent: false,
    auth_methods: %w(publickey),
    encryption: %w(aes128-ctr aes192-ctr aes256-ctr)
  }