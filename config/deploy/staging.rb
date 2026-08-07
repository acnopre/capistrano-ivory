# config/deploy/production.rb
server '45.79.88.130',user:'anopre',port:21703, roles: %w{web app laravel composer}
set :ssh_options, {
    keys: %w(/Users/allen.nopre/.ssh/id_ed25519),
    forward_agent: false,
    auth_methods: %w(publickey)
  }

#OIL SERVER