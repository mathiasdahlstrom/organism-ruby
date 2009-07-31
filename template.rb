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
    @config = Organism::Config.new("fonefood.yaml")    
    #setup rendering speed and quality
    frameRate $frame_rate
    smooth
    size @config.display_width, @config.display_height
  end
  
  def draw
    #ping the servers and see if new logs has arrived
    @config.do_process
  end

end


Template.new :title => "Organism Template", :width => 1280, :height => 720