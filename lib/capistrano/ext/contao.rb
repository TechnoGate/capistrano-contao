require 'active_support/core_ext/object/blank'
require 'capistrano/monkey_patches/fix_capture_conflict'
require 'capistrano/ext/helpers'
require 'capistrano/ext/git'
require 'capistrano_colors'
require 'capistrano/ext/custom_colors'
require 'capistrano/ext/decouple_from_rails'
require 'capistrano/ext/contao_assets'
require 'capistrano/ext/database'
require 'capistrano/ext/server'
require 'capistrano/ext/deploy'
require 'capistrano/ext/item'
require 'capistrano/ext/content'
require 'capistrano/ext/multistage'
require 'capistrano/ext/multistage_extensions'

Capistrano::Configuration.instance(:must_exist).load do
  Rails.env = 'production'

  namespace :contao do
    desc '[internal] Setup contao'
    task :setup, :roles => :app, :except => { :no_release => true } do
      # Empty task, the rest should hook to it
    end

    desc '[internal] Setup contao shared contents'
    task :setup_shared_folder, :roles => :app, :except => { :no_release => true } do
      shared_path = fetch :shared_path
      run <<-CMD
        #{try_sudo} mkdir -p #{shared_path}/logs &&
        #{try_sudo} mkdir -p #{shared_path}/config
      CMD

      # TODO: The deny access should follow denied_access config
      deny_htaccess = "order deny,allow\n"
      deny_htaccess << "deny from all"

      put deny_htaccess, "#{shared_path}/logs/.htaccess"
    end

    desc '[internal] Setup contao localconfig'
    task :setup_localconfig, :roles => :app, :except => { :no_release => true } do
      localconfig_php_config_path = "#{fetch :shared_path}/items/public,system,config,localconfig.php"
      on_rollback { run "rm -f #{localconfig_php_config_path}" }
      db_credentials = fetch :db_credentials

      localconfig = File.read('config/examples/localconfig.php.erb')
      load 'config/initializers/contao.rb'
      TechnoGate::Contao::Application.load_global_config!

      config = TechnoGate::Contao::Application.config.dup

      db_credentials_for_config = {
        'host'     => db_credentials[:hostname],
        'port'     => db_credentials[:port].present? ? db_credentials[:port] : nil,
        'user'     => db_credentials[:username],
        'pass'     => db_credentials[:password],
        'database' => fetch(:db_database_name),
      }

      config.contao.global.send("#{fetch :db_server_app}=", ActiveSupport::OrderedOptions.new)
      db_credentials_for_config.each do |k, v|
        config.contao.global.send("#{fetch :db_server_app}").send("#{k}=", v)
      end

      write ERB.new(localconfig, nil, '-').result(binding), localconfig_php_config_path
    end

    desc '[internal] Link files from contao to inside public folder'
    task :link_files, :roles => :app, :except => { :no_release => true } do
      deep_link "#{fetch :latest_release}/contao",
        "#{fetch :latest_release}/public"
    end

    desc '[internal] Fix contao symlinks to the shared path'
    task :fix_links, :roles => :app, :except => { :no_release => true } do
      run <<-CMD
        #{try_sudo} rm -rf #{fetch :latest_release}/public/system/logs;
        #{try_sudo} ln -nsf #{fetch :shared_path}/logs #{fetch :latest_release}/public/system/logs
      CMD
    end
  end

  # Dependencies
  after 'deploy:setup', 'contao:setup'
  after 'contao:setup', 'contao:setup_shared_folder'
  after 'contao:setup', 'contao:setup_localconfig'
  after 'deploy:finalize_update', 'contao:link_files'
  after 'contao:link_files', 'contao:fix_links'

  # Assets
  before 'deploy:finalize_update', 'contao:assets'

  # Database credentions
  before 'contao:setup_localconfig', 'db:credentials'
  before 'contao:setup_db', 'db:credentials'
end
