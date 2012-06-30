# https://github.com/capistrano/capistrano/issues/168#issuecomment-4144687
# XXX: Remove once https://github.com/capistrano/capistrano/pull/175 has been released
Capistrano::Configuration::Namespaces::Namespace.class_eval do
  def capture(*args)
    parent.capture *args
  end
end
