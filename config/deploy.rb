# config valid for current version and patch releases of Capistrano
lock "~> 3.20.1"

set :application, "ivorry"
set :repo_url, "git@github.com:acnopre/hpdai.git"
set :pty, true
# Default branch is :master
set :branch, ENV["branch"] || "main"
# Default deploy_to directory is /var/www/laravel-capistrano
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
                execute :php, "artisan config:cache"
                execute :php, "artisan route:clear"
                execute :php, "artisan route:cache"
                execute :php, "artisan view:clear"
                execute :php, "artisan view:cache"
                execute :php, "artisan event:clear"
                execute :php, "artisan event:cache"
                execute :php, "artisan cache:clear"
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
        require 'json'
        require 'base64'
        require 'tmpdir'

        repo_url  = fetch(:repo_url)
        tmp_dir   = Dir.mktmpdir('cap_git')

        begin
            system("git clone --bare #{repo_url} #{tmp_dir} -q")

            all_tags = `git -C #{tmp_dir} tag --sort=version:refname`.strip.split("\n").map(&:strip).reject(&:empty?)

            if all_tags.empty?
                puts "No tags found — skipping version sync."
                next
            end

            tags_data = all_tags.each_with_index.map do |tag, i|
                hash    = `git -C #{tmp_dir} rev-parse --short #{tag} 2>/dev/null`.strip
                date    = `git -C #{tmp_dir} log -1 --format=%cI #{tag} 2>/dev/null`.strip
                prev    = all_tags[i - 1] if i > 0
                range   = prev ? "#{prev}..#{tag}" : tag
                raw_log = `git -C #{tmp_dir} log #{range} --pretty=format:'%h|%cI|%s' 2>/dev/null`.strip

                changes = []
                raw_log.each_line do |line|
                    line = line.strip.gsub(/^'|'$/, '')
                    next if line.empty?
                    commit_hash, commit_date, subject = line.split('|', 3)
                    next if subject.nil?
                    if subject.start_with?('feat:')
                        changes << { type: 'Feature', description: subject.sub(/^feat:\s*/, ''), hash: commit_hash, date: commit_date }
                    elsif subject.start_with?('fix:')
                        changes << { type: 'Bug Fix', description: subject.sub(/^fix:\s*/, ''), hash: commit_hash, date: commit_date }
                    elsif subject.match?(/^(refactor|perf|chore):/)
                        changes << { type: 'Improvement', description: subject.sub(/^[^:]+:\s*/, ''), hash: commit_hash, date: commit_date }
                    end
                end

                { version: tag, hash: hash, date: date, changes: changes }
            end

            all_tags_b64 = Base64.strict_encode64(tags_data.to_json)

            on roles(:laravel) do
                within release_path do
                    execute :php, "artisan version:sync --all-tags-b64=#{all_tags_b64}"
                end
            end
        ensure
            FileUtils.rm_rf(tmp_dir)
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