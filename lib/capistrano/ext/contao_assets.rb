Capistrano::Configuration.instance(:must_exist).load do
  namespace :contao do
    namespace :assets do
      desc '[internal] Upload contao assets'
      task :default, :roles => :app, :except => { :no_release => true } do
        transaction do
          precompile
          path = File.join 'public', Rails.application.config.assets.prefix
          upload(path, "#{fetch :latest_release}/#{path}", :via => :scp, :recursive => true)
          clean
        end
      end

      desc '[internal] Generate assets'
      task :precompile, :roles => :app, :except => { :no_release => true } do
        on_rollback { find_and_execute_task 'contao:assets:clean' }
        run_locally 'bundle exec rake assets:precompile'
      end

      desc '[internal] Clean assets'
      task :clean, :roles => :app, :except => { :no_release => true } do
        run_locally 'bundle exec rake assets:clean'
      end
    end
  end
end
