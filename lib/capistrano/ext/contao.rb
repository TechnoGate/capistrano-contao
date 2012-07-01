require 'active_support/core_ext/object/blank'
require 'capistrano/monkey_patches/fix_capture_conflict'
require 'capistrano/ext/helpers'
require 'capistrano/ext/git'
require 'capistrano/ext/custom_colors'
require 'capistrano/ext/decouple_from_rails'
require 'capistrano/ext/contao_assets'
require 'capistrano/ext/database'
require 'capistrano/ext/server'
require 'capistrano/ext/deploy'

unless Capistrano::Configuration.respond_to?(:instance)
  abort 'capistrano/ext/contao requires capistrano 2'
end

Capistrano::Configuration.instance(:must_exist).load do
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
      localconfig_php_config_path = "#{fetch :shared_path}/config/public_system_config_localconfig.php"
      on_rollback { run "rm -f #{localconfig_php_config_path}" }
      db_credentials = fetch :db_credentials

      localconfig = File.read('config/examples/localconfig.php.erb')

      config = TechnoGate::Contao::Application.config.contao_global_config

      if !config || config.install_password.blank? || config.encryption_key.blank?
        message = <<-EOS
          You did not set the install password, and the encryption key in your
          #{ENV['HOME']}/.contao/config.yml, I cannot generate a localconfig
          since the required configuration keys are missing.
        EOS
        message.gsub!(/ [ ]+/, ' ').gsub!(/\n/, '').gsub!(/^ /, '')
        logger.important message if logger
        abort 'Required configurations are not set'
      else
        config = config.clone
        config.application_name = TechnoGate::Contao::Application.name
        config.db_server_app = fetch :db_server_app
        config.db_database   = fetch :db_database_name

        [:hostname, :port, :username, :password].each do |item|
          if db_credentials[item].present?
            config.send "db_#{item}=", db_credentials[item]
          end
        end

        write ERB.new(localconfig).result(binding), localconfig_php_config_path
      end
    end

    desc '[internal] Link files from contao to inside public folder'
    task :link_contao_files, :roles => :app, :except => { :no_release => true } do
      files = exhaustive_list_of_files_to_link("#{fetch :latest_release}/contao", "#{fetch :latest_release}/public")
      commands = files.map do |list|
        "#{try_sudo} ln -nsf #{list[0]} #{list[1]}"
      end

      begin
        run commands.join(';')
      rescue Capistrano::CommandError
        abort 'Unable to create to link contao files'
      end
    end

    desc '[internal] Fix contao symlinks to the shared path'
    task :fix_links, :roles => :app, :except => { :no_release => true } do
      latest_release = fetch :latest_release
      shared_path = fetch :shared_path

      # Remove files
      run <<-CMD
        #{try_sudo} rm -rf #{latest_release}/public/system/logs
      CMD

      # Create symlinks
      run <<-CMD
        #{try_sudo} ln -nsf #{shared_path}/logs #{latest_release}/public/system/logs
      CMD
    end
  end

  # Dependencies
  after 'deploy:setup', 'contao:setup'
  after 'contao:setup', 'contao:setup_shared_folder'
  after 'contao:setup', 'contao:setup_localconfig'
  after 'deploy:finalize_update', 'contao:link_contao_files'
  after 'contao:link_contao_files', 'contao:fix_links'

  # Assets
  after 'contao:link_contao_files', 'contao:assets:deploy'

  # Database credentions
  before 'contao:setup_localconfig', 'db:credentials'
  before 'contao:setup_db', 'db:credentials'
end
