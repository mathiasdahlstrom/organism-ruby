# Template
require 'lib/organism_requirements'
#debug variable,
$DBG=0
#should stdout message be suppressed
$VRB=0
#Variables to control the animation
$frame_rate = 25.0


class Template < Processing::App

  def setup
    #Read server configuration and connect to servers
    @config = Organism::Config.new("sinwave.yaml")    
    #setup rendering speed and quality
    frameRate $frame_rate
    smooth
    size @config.display_width, @config.display_height
    #properties for the wave
    @xspacing = 8     #How far apart should each horizontal location be spaced
    @w = width + 16   #Width of entire wave
    @theta = 0.0      #Start angle at 0
    @amplitude = 75.0 #Height of wave
    @period = 500.0   #How many pixels before the wave repeats
    #Value for incrementing X, a function of period and xspacing
    @dx = (TWO_PI / period) * xspacing
    @yvalues = Array.new @w/@xspacing
  end
  
  def draw
    #ping the servers and see if new logs has arrived
    @config.do_process
  end

end


Template.new :title => "Organism Template", :width => 1280, :height => 720