unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/contao requires Capistrano 2"
end

Capistrano::Configuration.instance.load do
  namespace :contao do
    namespace :assets do
      desc "[internal] Upload contao assets"
      task :deploy, :roles => :app, :except => { :no_release => true } do
        path = File.join 'public', Rails.application.config.assets.prefix
        upload(path, "#{fetch :latest_release}/#{path}", :via => :scp, :recursive => true)
      end

      desc "[internal] Generate assets"
      task :precompile, :roles => :app, :except => { :no_release => true } do
        run_locally "bundle exec rake assets:precompile"
      end

      desc "[internal] Clean assets"
      task :clean, :roles => :app, :except => { :no_release => true } do
        run_locally "bundle exec rake assets:clean"
      end
    end
  end

  before 'contao:assets:deploy', 'contao:assets:precompile'
  after  'contao:assets:deploy', 'contao:assets:clean'
end
