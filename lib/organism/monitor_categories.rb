module Organism
  class MonitorCategory
    
    attr_accessor :size, :order, :elements
    
    def initialize yaml_configuration
      @size = yaml_configuration["size"].to_i unless yaml_configuration["size"].nil?
      @order = yaml_configuration["order"].to_i unless yaml_configuration["order"].nil?
      @elements = []
    end
    
    def add_event category_event
      @elements.insert 0, category_event
      if @elements.size > @size-1
        @elements = @elements[0,@size-1] 
      end
    end
    
  end
  
  class ServerMonitor
   
     attr_accessor :source, :categories, :name
   
     def initialize server_name
       @name = server_name
       @source = nil
       #create categories hash and parse the monitor_categories section to populate it
       @categories = Hash.new
     end
     
      def add_block(name)
         puts 'ServerMonitor.add_block: NOT IMPLEMENTED YET'
         puts name
         puts '--------------------------------------------'
      end

      #callback from server when it performs some action
      def add_activity(source, options = { })
        category = @categories[options[:block]];
        category.add_event({ :name => source.name, :color => source.color, :options => options}) unless category.nil?
      end

      #callback from server when an event occured that has a descripted message
      def add_event(source, options = { })
         category = @categories[options[:block]];
         category.add_event({ :name => source.name, :color => source.color, :options => options}) unless category.nil?
      end
      
      def do_process
        @source.process
      end
      
      def server_type
        return @source.parser.class.to_s
      end
   end
   
end