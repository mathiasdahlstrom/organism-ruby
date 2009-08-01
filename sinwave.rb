#
# Quick sample of rendering the request load of the server as sin wave that changes its color from green to red,
# as the request times on the server increased. Based on the sinwave example code on processing.org
#
require 'lib/organism_requirements'
#debug variable,
$DBG=0
#should stdout message be suppressed
$VRB=0
#Variables to control the animation
$frame_rate = 25.0

class SinWave < Processing::App

  def setup
    #Read server configuration and connect to servers
    @config = Organism::Config.new("sinwave.yaml")    
    #setup rendering speed and quality
    frameRate $frame_rate
    smooth
    size @config.display_width, @config.display_height
    
    #properties for the wave
    @xspacing = 16     #How far apart should each horizontal location be spaced
    @w = width + 16   #Width of entire wave
    @theta = 0.0      #Start angle at 0
    @amplitude = 75.0 #Height of wave
    @period = width/2   #How many pixels before the wave repeats
    #Value for incrementing X, a function of period and xspacing
    @dx = (TWO_PI / @period) * @xspacing
    @yvalues = Array.new @w/@xspacing
    
    #Two values used to determin the max and min request length 
    $max_request_size = 1.9
    $min_request_size = 0.1
    
    #colors used by lerp function to set the color for drawing the wave
    $fromColor = color(0,255,0,50) #when low server load
    $toColor = color(255,0,0,50) #when high server load
    
  end
  
  def draw
    #ping the servers and see if new logs has arrived
    @config.do_process
    #Draw the state of the wave in this frame
    background 0
    calc_wave
    render_wave
  end

  def calc_wave
    @theta += 0.02
    x = @theta
    @yvalues.each_index do |index|
      @yvalues[index] = sin(x)*@amplitude
      x += @dx
    end
  end
  
  def render_wave
    @yvalues.each_index do |index|
      noStroke
      fill calc_color
      ellipseMode CENTER
      ellipse(index*@xspacing,height/2+@yvalues[index],16,16);
    end
  end
  
  def calc_color
    server_array =  @config.servers.to_a
    current_request_load = calc_average_load(server_array[0][1])
    return lerpColor($fromColor,$toColor,current_request_load)
  end
  
  def calc_average_load server
    urls = server.categories["urls"]
    values = Array.new
    urls.elements.each do |url|
      values << url[:options][:size]
    end
    normalized_weight = norm(values.average, $min_request_size, $max_request_size);
    return normalized_weight
  end
end


SinWave.new :title => "Server sin wave", :width => 1280, :height => 720