

module Organism
  module Source
    
    class Base
      require 'pp'
      
      #Objects used by any source
      attr_accessor :parser, :config, :name, :color
      
      #variables for the Source instance 
      attr_accessor :command, :file
      
      def initialize(server_name, config_yaml, config)
        @config = config
        @parser= config_yaml['parser']
        klass = Organism::Parser::Parser.registry[config_yaml['parser'].to_sym]
        if(klass != nil)
          @parser = klass.new(self)
        else
          raise "Couldnt find a Parser by name: #{name}, try --parsers for a list of available parsers"
        end
        @command = config_yaml['command']
        @file =  config_yaml['files']
        @name = server_name
        @color = config_yaml['color']
      end
      
      def process
        raise "#{self.class.to_s} does not implement .process"
      end
      
      def update
        raise "#{self.class.to_s} does not implement .update"
      end
    
      def add_activity( opts = {} )
        @config.add_activity( self, opts )
      end

      def add_event( opts = {} )
        @config.add_event( self, opts )
      end    
    end
  end
end
