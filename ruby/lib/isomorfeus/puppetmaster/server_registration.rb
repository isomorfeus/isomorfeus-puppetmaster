Isomorfeus::Puppetmaster.register_server :agoo do |app, port, _host, **options|
  begin
    require 'rack/handler/agoo'
  rescue LoadError
    raise LoadError, "Unable to load 'agoo' as server."
  end

  events.log 'Puppetmaster starting Agoo...'
  events.log "* Version #{Agoo::VERSION}"

  Rack::Handler::Agoo.run(app, { port: port }.merge(options)).join
end

Isomorfeus::Puppetmaster.register_server :puma do |app, port, host, **options|
  begin
    require 'rack/handler/puma'
  rescue LoadError
    raise LoadError, "Unable to load 'puma' as server."
  end
  # If we just run the Puma Rack handler it installs signal handlers which prevent us from being able to interrupt tests.
  # Therefore construct and run the Server instance ourselves.
  # Rack::Handler::Puma.run(app, { Host: host, Port: port, Threads: "0:4", workers: 0, daemon: false }.merge(options))
  options = { Host: host, Port: port, Threads: '0:4', workers: 0, daemon: false }.merge(options)
  conf = Rack::Handler::Puma.config(app, options)
  events = conf.options[:Silent] ? ::Puma::Events.strings : ::Puma::Events.stdio

  events.log 'Puppetmaster starting Puma...'
  events.log "* Version #{Puma::Const::PUMA_VERSION} , codename: #{Puma::Const::CODE_NAME}"
  events.log "* Min threads: #{conf.options[:min_threads]}, max threads: #{conf.options[:max_threads]}"

  Puma::Server.new(conf.app, events, conf.options).tap do |s|
    s.binder.parse conf.options[:binds], s.events
    s.min_threads, s.max_threads = conf.options[:min_threads], conf.options[:max_threads]
  end.run.join
end

Isomorfeus::Puppetmaster.server = :puma