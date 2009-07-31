# Your starting point for daemon specific classes. This directory is
# already included in your load path, so no need to specify it.

module RuoteKit

  autoload :Configuration, "ruote-kit/configuration"
  autoload :Racker,        "ruote-kit/racker"

  class << self
    # The instance of ruote
    attr_accessor :engine

    # Instance of rack app
    attr_accessor :rack

    # Instance of server handler
    attr_accessor :server

    # Configure and run the engine in a RESTful container
    def run!(&block)
      yield if block_given?

      configure_engine
      configure_rack
    end

    def shutdown!( purge_engine = false )
      shutdown_rack
      shutdown_engine( purge_engine )
    end

    def configuration
      unless @configuration
        @configuration = Configuration.new
        config = @configuration
        eval( IO.read( @configuration.user_file ), binding, @configuration.user_file ) if File.exist?( @configuration.user_file )
      end

      @configuration
    end

    private

    def configure_engine
      self.engine = configuration.engine_class.new

      self.engine.register_participant('.*', configuration.catchall_participant)
    end

    def shutdown_engine( purge = false )
      self.engine.shutdown

      if purge
        self.engine.context.values.each do |s|
          s.purge if s.respond_to?(:purge)
        end
      end

      self.engine = nil
    end

    def configure_rack
      self.rack = RuoteKit::Racker.to_app

      return if %w(test cucumber).include? DaemonKit.env

      Thread.new {
        self.server = configuration.rack_handler_class.run( self.rack, configuration.rack_options )
      }
    end

    def shutdown_rack
    end
  end
end
