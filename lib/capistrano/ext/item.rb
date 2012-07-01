Capistrano::Configuration.instance(:must_exist).load do
  set :shared_item_path, -> { "#{fetch :shared_path}/items" }

  namespace :item do
    desc '[internal] Symlink all items'
    task :link, :roles => :app do
      link_items fetch(:shared_item_path),
        fetch(:latest_release)
    end

    desc '[internal] Setup shared items'
    task :setup, :roles => :app do
      fetch(:shared_items, []).each do |item|
        item_shared_path = "#{fetch :shared_item_path}/#{item.gsub /\//, ','}"
        item_public_path = "#{fetch :latest_release}/#{item}"

        unless remote_file_exists? item_shared_path
          if remote_file_exists? "#{item_public_path}.default"
            run "#{try_sudo} cp #{item_public_path}.default #{item_shared_path}"
            logger.important "#{item_public_path}.default copied to #{item_shared_path}"
          else
            write '', item_shared_path
            logger.important "#{item_shared_path} has been initialized with an empty file"
          end
        end
      end
    end
  end

  # Internal Dependencies
  before 'item:link', 'item:setup'

  # External Dependencies
  before 'deploy:restart', 'item:link'
end
