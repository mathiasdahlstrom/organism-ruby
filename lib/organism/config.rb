
module Organism

  class Config
    require 'yaml'
    
    attr_accessor :categories, :servers, :display_width, :display_height
    
    def initialize(yaml_file)
      #load yaml file that contains configuration
      @yaml_configuration = YAML.load_file(yaml_file)
      
      #create servers hash and parse the servers section to populate it
      @servers = Hash.new
      create_server_sources(@yaml_configuration['servers'])
      screen_dimension = @yaml_configuration['display']['dimensions'].split('x')
      @display_width = screen_dimension[0].to_i
      @display_height = screen_dimension[1].to_i
    end
  
    def do_process
      @servers.each_value do |server|
        server.do_process
      end
    end
    
    private
    
    def create_server_sources properties_hash
      properties_hash.each do |server|
        server_monitor = Organism::ServerMonitor.new server[0]
        server_monitor.source = Organism::Source::SSH.new(server[0], server[1], server_monitor)
        @servers[server[0]] = server_monitor
        create_categories server_monitor, server[1]['monitor_categories']
        server_monitor.source.init
      end
    end
    
    def create_categories server, properties_hash
      properties_hash.each_key do |category_name|
        server.categories[category_name] = Organism::MonitorCategory.new properties_hash[category_name]
      end
    end
  
  end
  
end
