# config/deploy/production.rb
server '129.212.236.65',user:'allen', roles: %w{web app laravel composer}
set :ssh_options, {
    keys: %w(/Users/ayenopre/.ssh/id_rsa_ivory),
    forward_agent: false,
    auth_methods: %w(publickey)
  }