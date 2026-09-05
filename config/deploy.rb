# config valid for current version and patch releases of Capistrano
lock "~> 3.17.2"

set :application, "ivorry"
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
            # execute :sudo, "chmod -R 775 #{shared_path}/storage/logs/"
        end
    end
    task :artisan do
        on roles(:laravel) do
            within release_path do
                execute :php, "artisan config:clear"
                execute :php, "artisan cache:clear"
                execute :php, "artisan view:clear"
                execute :php, "artisan storage:link"
                execute :php, "artisan migrate --force"
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
        on roles(:laravel) do
            execute :cp, "#{dotenv_file} #{release_path}/.env"
        end
    end

    task :sync_version do
        repo_path = File.expand_path('~/ivorry')
        git_tag   = `git -C #{repo_path} describe --tags --exact-match HEAD 2>/dev/null`.strip

        if git_tag.empty?
            puts "No exact tag on HEAD — skipping version sync."
            next
        end

        git_hash = `git -C #{repo_path} rev-parse --short HEAD 2>/dev/null`.strip
        prev_tag = `git -C #{repo_path} describe --tags --abbrev=0 HEAD^ 2>/dev/null`.strip
        range    = prev_tag.empty? ? git_tag : "#{prev_tag}..#{git_tag}"
        raw_log  = `git -C #{repo_path} log #{range} --pretty=format:'%s' 2>/dev/null`.strip

        changes = []
        raw_log.each_line do |line|
            line = line.strip.gsub(/^'|'$/, '')
            next if line.empty?
            if line.start_with?('feat:')
                changes << { type: 'Feature', description: line.sub(/^feat:\s*/, '') }
            elsif line.start_with?('fix:')
                changes << { type: 'Bug Fix', description: line.sub(/^fix:\s*/, '') }
            elsif line.match?(/^(refactor|perf|chore):/)
                changes << { type: 'Improvement', description: line.sub(/^[^:]+:\s*/, '') }
            end
        end

        require 'json'
        require 'base64'
        changes_b64 = Base64.strict_encode64(changes.to_json)

        on roles(:laravel) do
            within release_path do
                execute :php, "artisan version:sync --app-version=#{git_tag} --git-hash=#{git_hash} --changes-b64=#{changes_b64}"
            end
        end
    end
end


namespace :deploy do
    after :updated, "laravel:configure_dot_env"
    after :updated, "composer:install"
    after :updated, "laravel:fix_permission"
    after :updated, "laravel:artisan"
    after "laravel:artisan", "laravel:sync_version"
end