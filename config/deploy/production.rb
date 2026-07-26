# config/deploy/production.rb
server '129.212.236.65',user:'allen', roles: %w{web app laravel composer}
set :ssh_options, {
    keys: %w(/Users/allen.nopre/.ssh/id_rsa),
    forward_agent: false,
    auth_methods: %w(publickey),
    encryption: %w(aes128-ctr aes192-ctr aes256-ctr)
  }