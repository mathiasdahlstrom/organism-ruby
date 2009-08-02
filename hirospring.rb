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
#how much each tree depth adds to the y position of the spring
$y_increment_per_depth = 100

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
    @roots = Array.new
  end
  
  def draw
    @config.do_process
    check_for_nodes
    background 120,120,120
    @roots.each do |spring|
      draw_spring spring
    end
  end

  def draw_spring spring
    spring.update
    spring.display
    spring.children.each do |child|
      draw_spring child
    end
  end
  
  def create_springs name_array
    parent_key = '/' + name_array[0..-2].join("/")
    if @springs.has_key? parent_key
      parent_node = @springs[parent_key]
      key = '/' + name_array.join('/');
      node_depth = key.count('/')
      node = create_node(width/2, (node_depth*$y_increment_per_depth), 0.95)
      parent_node.children << node
      node.parent = parent_node
      node.depth = node_depth
      @springs[key] = node
    else
      if name_array.size > 1
        #walk up the tree
        parent_node = create_springs name_array[0..-2]
        key = '/' + name_array.join('/');
        node_depth = key.count('/')
        node = create_node(width/2, (node_depth*$y_increment_per_depth), 0.95)
        parent_node.children << node
        node.parent = parent_node
        key = '/' + name_array.join('/');
        node.depth = node_depth
        @springs[key] = node
      else
        #root create node
        key = '/' + name_array.join('/');
        node_depth = key.count('/')
        node = create_node(width/2, (node_depth*$y_increment_per_depth), 0.95)
        node.depth = node_depth
        @springs[key] = node
        @roots << node
      end
    end
    return node
  end
  
  def check_for_nodes
    has_new_node = false
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
            has_new_node = true
          end
         end
         entry[:rendered] = true
      end
    end
    if has_new_node
      update_node_pos @roots, (width/@roots.size)/2
    end
  end
  
  def create_node(x, y, scale)
    Spring.new(x,  y,  $node_size*scale, 0.98, 9.0, 0.1, 0)
  end
  
  def create_node_with_parent(parentNode, x, y, scale)
    node = Spring.new(x,  y,  $node_size*scale, 0.98, 9.0, 0.1, 0)
    node.parent = parentNode
    return node
  end
  
  def update_node_pos nodeArray, width_for_depth
    if nodeArray.size == 0 || width_for_depth == 0
      return
    end
    x_increment = width_for_depth/nodeArray.size
    nodeArray.each_index do |index|
      node = nodeArray[index]
      node.update_xy x_increment*(index+1), node.ypos
      update_node_pos node.children, x_increment*(index+1)
    end
  end
  
  class Spring
    #Screen values
    attr_accessor :xpos, :ypos, :tempxpos, :tempypos, :size, :over, :move, :me, :depth

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

    def update_xy x, y
      @xpos = @tempxpos = x; 
      @ypos = @tempypos = y;
      @rest_posx = x;
      @rest_posy = y;
    end
    
  end
  
end

Hirospring.new :title => "Hirospring" , :width => 640, :height => 480