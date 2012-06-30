unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/decouple_from_rails requires capistrano 2"
end

Capistrano::Configuration.instance.load do
  # Prevent capistrano from creating log, system and pids folders.
  set :shared_children, Array.new

  namespace :deploy do
    desc "Empty task, overriden by #{__FILE__}"
    task :finalize_update do
      # Empty task, we do not want to delete the system folder.
    end
  end
end
