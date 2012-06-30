if Capistrano::Logger.respond_to? :add_color_matcher
  Capistrano::Logger.add_color_matcher({
    :match => /adapter:|hostname:|username:|password:/,
    :color => :red,
    :level => Capistrano::Logger::TRACE,
    :prio => -20,
    :attribute => :blink
  })

  Capistrano::Logger.add_color_matcher({
    :match => /WARNING:/,
    :color => :yellow,
    :level => Capistrano::Logger::INFO,
    :prio => -20
  })

  Capistrano::Logger.add_color_matcher({
    :match => /ERROR:/,
    :color => :red,
    :level => Capistrano::Logger::IMPORTANT,
    :prio => -20
  })
end
