#
# Hirospring
#
require 'lib/organism_requirements'
#debug variable,
$DBG=0
#should stdout message be suppressed
$VRB=0
#Variables to control the animation
$frame_rate = 25.0
#size of root node
$node_size = 20.0
#maxium tree depth, urls deeper does not get drawn
$max_tree_depth = 4

class Hirospring < Processing::App
  attr_accessor :springs
  def setup
    #Read server configuration and connect to servers
    @config = Organism::Config.new("hirospring.yaml")    
    #setup rendering speed and quality
    frameRate $frame_rate
    size @config.display_width, @config.display_height
    noStroke 
    smooth
    @springs = Hash.new
   
  end
  
  def draw
    @config.do_process
    check_for_nodes
    background 120,120,120
    @springs.each_value do |spring|
      spring.update
      spring.display
    end
  end

  def check_for_nodes
    @config.get_all_entries_for_category("urls").each do |entry|
      if !entry.has_key?(:rendered)
         relative_url_without_params = entry[:options][:name].split('?').first
         spring_name_array = relative_url_without_params.split('/')
         spring_name_array = spring_name_array[1..-1]
         if spring_name_array.size <= $max_tree_depth
          if @springs.has_key? relative_url_without_params
            spring = @springs[relative_url_without_params]
            spring.update_pos(15, 0.3)
          else
            spring = create_springs(spring_name_array)
          end
         end
         entry[:rendered] = true
      end
    end
  end
  
  def create_springs name_array
    parent_key = '/' + name_array[0..-2].join("/")
    if @springs.has_key? parent_key
      parent_node = @springs[parent_key]
      node = create_node(width/2, height/2, 0.95)
      parent_node.children << node
      node.parent = parent_node
      key = '/' + name_array.join('/');
      @springs[key] = node
    else
      if name_array.size > 1
        #walk up the tree
        parent_node = create_springs name_array[0..-2]
        node = create_node(width/2, height/2, 0.95)
        parent_node.children << node
        node.parent = parent_node
        key = '/' + name_array.join('/');
        @springs[key] = node
      else
        #root create node
        key = '/' + name_array.join('/');
        node = create_node(width/2, height/2, 0.95)
        @springs[key] = node
      end
    end
    return node
  end
  
  def mouseReleased
    @springs[1].update_pos 15, 0.3
  end
  
  def create_node(x, y, scale)
    Spring.new(x,  y,  $node_size*scale, 0.98, 9.0, 0.1, 0)
  end
  
  def create_node_with_parent(parentNode, x, y, scale)
    node = Spring.new(x,  y,  $node_size*scale, 0.98, 9.0, 0.1, 0)
    node.parent = parentNode
    return node
  end
  
  class Spring
    #Screen values
    attr_accessor :xpos, :ypos, :tempxpos, :tempypos, :size, :over, :move, :me

    #Spring simulation constants 
    attr_accessor :mass, :k, :damp, :rest_posx, :rest_posy

    #Spring simulation variables 
    attr_accessor :velx, :vely, :accel, :force
    
    attr_accessor :parent,:children
    
    #Constructor
    def initialize(x,y,s,d,m,k_in,id)
      #default screen drawing values
      @children = Array.new
      @size = 20; 
      @over = false; 
      @move = false;
      @tempxpos = 0.0
      @tempypos = 0.0      
      #Spring simulation defaults
      @k = 0.2;    #Spring constant 
      @velx = 0.0;   #// X Velocity 
      @vely = 0.0;   #// Y Velocity 
      @accel = 0;    #// Acceleration 
      @force = 0;    #// Force
      
      #initialze the object
      @xpos = @tempxpos = x; 
      @ypos = @tempypos = y;
      @rest_posx = x;
      @rest_posy = y;
      @size = s;
      @damp = d; 
      @mass = m; 
      @k = k_in;
      @me = id;
    end

    def update 
      @force = -@k * (@tempypos - @rest_posy)   #f=-ky
      @accel = @force / @mass;                  # Set the acceleration, f=ma == a=f/m 
      @vely = @damp * (@vely + @accel);         # Set the velocity 
      @tempypos = @tempypos + @vely;            # Updated position 

      @force = -@k * (@tempxpos - @rest_posx);  # f=-ky 
      @accel = @force / @mass;                  # Set the acceleration, f=ma == a=f/m 
      @velx = @damp * (@velx + @accel);         # Set the velocity 
      @tempxpos = @tempxpos + @velx;            # Updated position
    end

    #Test to see if mouse is over this spring
    def over()
      disX = @tempxpos - mouseX;
      disY = @tempypos - mouseY;
      if (Math.sqrt(sq(disX) + sq(disY)) < size/2 )
        return true;
      else
        return false;
      end
    end

    #Draw the parents with the alwith half of the size 
    def update_pos change, k_in
      @rest_posy = @ypos;
      @tempypos += change;
      @k = k_in
      @parent.update_pos(change/2, k_in/4) unless @parent.nil?
    end

    def display
      ellipse(tempxpos, tempypos, size, size);
      stroke 140
      if !@parent.nil?
        line(tempxpos, tempypos, @parent.tempxpos, @parent.tempypos)
      end
    end


  end
  
end

Hirospring.new :title => "Hirospring" , :width => 640, :height => 480