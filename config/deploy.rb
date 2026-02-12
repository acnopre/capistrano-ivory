# config valid for current version and patch releases of Capistrano
lock "~> 3.17.2"

set :application, "ivory"
set :repo_url, "git@github.com:acnopre/hpdai.git"
set :pty, true
# Default branch is :master
set :branch, ENV["branch"] || "main"
# Default deploy_to directory is /var/www/laravel-capistrano
set :deploy_to, '/var/www/html/ivory'
set :laravel_dotenv_file, '/var/www/html/secret/.env'
# Linked directories for a standard Laravel 5 application
set :laravel_5_linked_dirs, [
  'storage'
]
# Default value for keep_releases is 5
set :keep_releases, 5
append :linked_dirs, 
    'storage/app',
    'storage/framework/cache',
    'storage/framework/sessions',
    'storage/framework/views',
    'storage/logs',
    'storage/uploads'
    namespace :composer do
        desc "Running Composer Install"
        task :install do
            on roles(:composer) do
                within release_path do
                    execute :rm, "-rf #{release_path}/vendor"
                    execute :composer, "install --prefer-dist --optimize-autoloader --ignore-platform-req=php --no-scripts"
                    execute :rm, "-f #{release_path}/vendor/composer/platform_check.php"
                    execute :composer, "dump-autoload --optimize --no-scripts"
                end
            end
        end
    end
namespace :laravel do
    task :fix_permission do
        on roles(:laravel) do
            execute :chmod, "-R 775 #{release_path}/bootstrap/cache/"
            execute :chmod, "-R 775 #{release_path}/storage/"
        end
    end
    task :artisan do
        on roles(:laravel) do
            within release_path do
                execute :php, "artisan storage:link"
            end
        end
    end

    task :restart_workers do
        on roles(:laravel) do
            execute :sudo, :supervisorctl, "restart laravel-worker:*"
        end
    end

    task :configure_dot_env do
    dotenv_file = fetch(:laravel_dotenv_file)
        on roles (:laravel) do
        execute :cp, "#{dotenv_file} #{release_path}/.env"
        end
    end
end
namespace :deploy do
    after :updated, "laravel:configure_dot_env"
    after :updated, "composer:install"
    after :updated, "laravel:fix_permission"
end