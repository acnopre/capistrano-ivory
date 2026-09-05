# config/deploy/staging.rb
require 'dotenv'
Dotenv.load(File.expand_path('../../.env', __dir__))

server ENV['STAGING_SERVER'], user: ENV['STAGING_USER'], port: (ENV['STAGING_PORT'].to_i.nonzero? || 22), roles: %w{web app laravel composer}
set :deploy_to, ENV['STAGING_DEPLOY_TO']
set :laravel_dotenv_file, ENV['STAGING_DOTENV']
set :ssh_options, {
    keys: [ENV['STAGING_SSH_KEY']],
    forward_agent: false,
    auth_methods: %w(publickey),
    encryption: %w(aes128-ctr aes192-ctr aes256-ctr)
  }

#OIL SERVER
