require 'rubygems'
require 'sinatra'
require 'haml'
require 'osc'
require 'open-uri'
require 'logger'
require 'timeout'
require 'mongrel'
# require 'exception_handler'

Dir.chdir(File.dirname(__FILE__))

OscClient = OSC::UDPSocket.new

# HOSTS = %w(jklabs-mbp.local thing1.local thing2.local)
HOSTS = %w(thing1.local thing2.local)
LAZY_COMPUTER = 'thing2.local'
# LAZY_COMPUTER = 'jklabs-mbp.local'
# HEARTBEAT_URL = "http://google.com"
ART_SERVER = "http://172.16.220.40"
HEARTBEAT_URL = "http://sanjoseartcloud.org/heartbeat/?installation_id=3"
HEARTBEAT_DELAY = 60 # in seconds
SERVER_PORT = 4567

START_TIME = Time.now
MAX_RUNTIME = 60 * 60 * 24 # in seconds
# MAX_RUNTIME = 60  # in seconds

def set_shutdown_time
  d = Date.today+1
  $shutdown_time = Time.mktime(d.year, d.month, d.day, 3)
end

# d = Date.today
# SHUTDOWN_TIME = Time.mktime(d.year, d.month, d.day, 10, 13)

set_shutdown_time

$settings = {}
$hostname = nil

set :public, Proc.new { File.join(root,'dreaming','mugshots') }
set :server, 'mongrel'

# set :settings_path, Proc.new { File.join(root,'dreaming','settings.txt') }
SETTINGS_PATH = 'dreaming/settings.txt'


def logger
  @logger ||= Logger.new('dreaming/mugshots/log/sinatra.log', 10, 1024000)
end

def error_logger
  @error_logger ||= Logger.new('dreaming/mugshots/log/error.log', 10, 1024000)
end

def emergency_tweet(message)
  `curl -u jklabs:0BeuzxHbyfBu2w -d "from=dreamingfids&to=jkriss&message=#{message} #{hostname}" http://jklabs-notifier.heroku.com/message`
end

error do
  e = request.env['sinatra.error']
  error_logger.fatal "#{e.message} :\n #{e.backtrace.collect{ |line| "   #{line}"}.join("\n")}"
  emergency_tweet e.message
  "sorry, there was some kind of error. we've been notified."
end

def read_settings
  if File.exists?(SETTINGS_PATH)
    File.open(SETTINGS_PATH).read.strip.split('&').each { |line| vals = line.split("="); $settings[vals.first.intern] = vals[1] if vals.size > 1 }
    $settings.each_pair { |k,v| $settings[k] = false if v == 'false' }
    logger.warn "loaded #{$settings.inspect}"
  end
end

def hostname
  $hostname ||= `hostname`.strip
end

def uptime
  Time.now - START_TIME
end

def other_hosts
  HOSTS.reject{ |h| h == hostname }
end

# start heartbeat
configure do
  
  $last_heartbeat = nil
  
  if hostname == LAZY_COMPUTER
  
    logger.info "  - about to start heartbeat thread"
    heartbeat = Thread.new do
      while true do
        logger.info "pinging #{other_hosts.inspect}"
        check_auto_restart
        other_hosts.each do |h|
          url = "http://#{h}:#{SERVER_PORT}/heartbeat"
          logger.info "- about to ping #{url}"
          begin
            open(url)
          rescue Exception => e
            logger.warn "ERROR: #{e} URL: #{url}"
            # emergency_tweet "heartbeat error: #{e} #{url}"
          end
          logger.info "- ping #{url} at #{Time.now}"
        end
        sleep(HEARTBEAT_DELAY)
      end
    end
    
  else
  
    logger.info "registering status listeners"
    
    begin
      Timeout::timeout(3) do
        open "#{ART_SERVER}/status/?register=4567&tests=normal,test,stop,restart,reboot"
        logger.info "successfully registered status listeners"
      end
    rescue Timeout::Error
      logger.warn "status server not responding"
    end

  end
end

def unregister_status_listener
  unless hostname == LAZY_COMPUTER
    logger.info "unregistering status listener"
    begin
      Timeout::timeout(3) do
        open "#{ART_SERVER}/status/?unregister=4567"
        logger.info "successfully unregistered status listeners"
      end
    rescue Timeout::Error
      logger.warn "status server not responding"
    end
  end
end

def check_auto_restart
  if Time.now > $shutdown_time
    logger.warn "!! restarting after #{uptime.to_i} seconds !!"
    emergency_tweet("restarting")
    `./fishcontrol restart` if HOSTS.include?(hostname)
    set_shutdown_time
  end
end

before do
  check_auto_restart
end

post '/' do
  puts "status = #{params[:status]}"
  case params[:status]
  when 'normal'
    osc :behavior, 'i', 0 # first behavior
  when 'test'
    osc :showRawInput, 's', 'ptthbt'
  when 'stop'
    `./fishcontrol stop`
  when 'restart'
    `./fishcontrol restart`
  when 'reboot'
    echo '/reboot'
    `./fishcontrol reboot`
  end
end

get '/' do
  read_settings
  @settings = $settings
  logger.info "current settings: #{@settings.inspect}"
  haml :index
end

get '/fish' do
  haml :fishies
end

get '/heartbeat' do
  if hostname != LAZY_COMPUTER
    logger.info "got local ping, sending heartbeat to #{HEARTBEAT_URL}"
    $last_heartbeat = Time.now
    open(HEARTBEAT_URL)
  end
  redirect '/'
end

get '/restart_server' do
  `./fishcontrol server:restart`
end

get '/reboot' do
  echo '/reboot'
  `./fishcontrol reboot`
end

post '/upload' do
  `cd #{File.dirname(__FILE__)} && tar xf #{params[:code][:tempfile].path}`
  File.delete(params[:code][:tempfile].path)
  redirect '/'
end

get '/start' do
  cmd :start
  echo '/start'
  redirect '/'
end

get '/stop' do
  cmd :stop
  echo '/stop'
  redirect '/'
end

get '/restart' do
  cmd :restart
  echo '/restart'
  redirect '/'
end

get '/click' do
  osc :click
  redirect '/'
end

get '/fullscreen' do
  osc :fullscreen
  redirect '/'
end

get '/takeMugshot' do
  osc :takeMugshot
  redirect '/'
end

get '/behaviors/:id' do
  osc :behavior, 'i', params[:id].to_i
  redirect '/'
end

get '/test/input' do
  osc :showRawInput, 's', 'ptthbt'
  redirect '/'
end

get '/test/pattern' do
  osc :showTestPattern, 's', 'ptthbt'
  redirect '/'
end

get '/settings' do
  logger.info params.inspect
  %w(showBlobs cycleBehaviors showFrameRate useMovie randomCycleTime).each { |b| params[b.intern] ||= false }
  $settings = params
  osc :setSettings, 's', params.keys.collect{ |k| "#{k}=#{params[k]}" }.join("&")
  redirect '/'
end

get '/record' do
  osc :record, 'i', params[:frames].to_i
  redirect '/'
end

def echo(request_path)
  return if params[:echo] == 'false' || !HOSTS.include?(hostname)
  other_hosts.each do |h|
    url = "http://#{h}:#{SERVER_PORT}#{request_path}?echo=false"
    logger.debug "requesting #{url}"
    begin
      open url
    rescue Exception => e
      logger.warn "error loading url: #{e}"
    end
  end
end

def cmd(action)
  # this will need to run on both machines
  # just use ssh?
  `./fishcontrol #{action}`
end

def osc(method, arg_types='s', value='hi')
  m = OSC::Message.new("/fish/in/#{method}", arg_types, value)
  logger.debug "sending #{m.inspect}"
  OscClient.send m, 0, "230.0.0.1", 7447
end

# class Thin::Server
#   def stop!
#     puts "Stopping Thin..."
#     unregister_status_listener
#     @backend.stop!
#   end
# end

class Mongrel::HttpServer
  def stop(synchronous=false)
    puts "Stopping mongrel..."
    unregister_status_listener
    raise AcceptorError, "Server was not started." unless @acceptor
    @acceptor.raise(Mongrel::StopServer.new)
    (sleep(0.5) while @acceptor.alive?) if synchronous
    @acceptor = nil
  end
end


__END__

@@ layout
%html
  = yield
  
@@ fishies

- (1..36).each do |i| 
  - fish = "mugshot-#{i}.jpg"
  %a{ :href => fish }
    %img{ :src => fish, :width => 80, :border => 0 }

@@ index

:plain
  <style type="text/css"> 
    * {
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Helvetica', sans-serif;
      margin: 30;
      font-size: 0.8em;
    }

    p {
      margin-bottom: 30px;
    }

    a {
      color: #444;
      text-decoration: none;
      border: 1px dotted #444;
      padding: 5px;
      margin-right: 5px;
      font-weight: bold;
      font-size: 1.2em;
      letter-spacing: 0.7px;
    }

    a:hover {
      color: #000;
      border-style: solid;
    }
 
    fieldset {
      padding: 5px;
      zpadding-left: 0;
      border: 1px dotted #ccc;
      width: 300px;
      margin-bottom: 10px;
    }

    legend {
      font-weight: bold;
      padding: 5px
    }

    fieldset label {
      width: 100px;
      line-height: 1em !important;
      margin-bottom: 5px;
      display: inline-block;
    }
  </style>

%p
  %a{ :href => '/restart' } restart
  <-- press this if it looks frozen

%p
  %a{ :href => '/start' } start
  %a{ :href => '/stop' } stop
  %a{ :href => '/click' } click
  %a{ :href => '/takeMugshot' } take mugshot
  %a{ :href => '/fullscreen' } fullscreen
  %a{ :href => '/restart_server' } restart web server

%p
  %a{ :href => '/behaviors/0'} departures
  %a{ :href => '/behaviors/1'} mugshots
  %a{ :href => '/behaviors/2'} switching cameras
  %a{ :href => '/behaviors/3'} zooming

%p
  %a{ :href => '/test/input'} raw input
  %a{ :href => '/test/pattern'} test patterns
  
%p
  %form{ :action => '/settings' }

    all durations in frames
    %br
    %br
    
  
    %fieldset
      %legend general
      %label{ :for => 'useMovie' } use movie
      %input#useMovie{ :type => 'checkbox', :name => 'useMovie', :value => 'useMovie', :checked => $settings[:useMovie]}
      %br
      %label{ :for => 'cycleBehaviors' } cycle behaviors
      %input#cycleBehaviors{ :type => 'checkbox', :name => 'cycleBehaviors', :value => 'cycleBehaviors', :checked => $settings[:cycleBehaviors]}
      %br
      %label{ :for => 'cycleLength' } cycle length
      %input{ :type => 'number', :name => 'cycleLength', :value => $settings[:cycleLength] }

      %br
      %label{ :for => 'randomCycleTime' } randomize cycle time
      %input#randomCycleTime{ :type => 'checkbox', :name => 'randomCycleTime', :value => 'randomCycleTime', :checked => $settings[:randomCycleTime]}
      
      %br
      %label{ :for => 'minFramesPerBehavior' } min frames per behavior
      %input{ :type => 'number', :name => 'minFramesPerBehavior', :value => $settings[:minFramesPerBehavior] }
      
      %br
      %label{ :for => 'maxFramesPerBehavior' } max frames per behavior
      %input{ :type => 'number', :name => 'maxFramesPerBehavior', :value => $settings[:maxFramesPerBehavior] }
      
      %label{ :for => 'showFrameRate' } show framerate
      %input#showFrameRate{ :type => 'checkbox', :name => 'showFrameRate', :value => 'showFrameRate', :checked => $settings[:showFrameRate]}
      /
        %br
        %label{ :for => 'brightness' } brightness
        %input{ :type => 'number', :name => 'brightness', :value => $settings[:brightness] }
        %br
        %label{ :for => 'contrast' } contrast
        %input{ :type => 'number', :name => 'contrast', :value => $settings[:contrast] }

    
    %fieldset
      %legend mugshots
      %label{ :for => 'showBlobs' } show blobs
      %input#showBlobs{ :type => 'checkbox', :name => 'showBlobs', :value => 'showBlobs', :checked => $settings[:showBlobs]}
      %br
      %label{ :for => 'mugshotRectThreshold' } score threshold
      %input{ :type => 'number', :name => 'mugshotRectThreshold', :value => $settings[:mugshotRectThreshold] }
      %br
      %label{ :for => 'mugshotCameraInterval' } camera interval
      %input{ :type => 'number', :name => 'mugshotCameraInterval', :value => $settings[:mugshotCameraInterval] }
      %br
      
    %fieldset
      %legend departure board
      %label{ :for => 'departuresCameraInterval' } camera interval
      %input{ :type => 'number', :name => 'departuresCameraInterval', :value => $settings[:departuresCameraInterval] }
      %br
      %label{ :for => 'departuresBlinkRate' } blink rate
      %input{ :type => 'number', :name => 'departuresBlinkRate', :value => $settings[:departuresBlinkRate] }
      %br
      %label{ :for => 'departuresBlinkDuration' } # of blinks per
      %input{ :type => 'number', :name => 'departuresBlinkDuration', :value => $settings[:departuresBlinkDuration] }
      %br
      %label{ :for => 'departuresFramesBeforeNewBlink' } frames before new blink
      %input{ :type => 'number', :name => 'departuresFramesBeforeNewBlink', :value => $settings[:departuresFramesBeforeNewBlink] }
      %br
      %label{ :for => 'departuresShuffleInterval' } shuffle interval
      %input{ :type => 'number', :name => 'departuresShuffleInterval', :value => $settings[:departuresShuffleInterval] }
      %br
      %label{ :for => 'departuresShuffleSpeed' } shuffle delay
      %input{ :type => 'number', :name => 'departuresShuffleSpeed', :value => $settings[:departuresShuffleSpeed] }
      %br
      %label{ :for => 'departuresVideoOpacity' } video opacity (0-255)
      %input{ :type => 'number', :name => 'departuresVideoOpacity', :value => $settings[:departuresVideoOpacity] }
      %br
      %label{ :for => 'departuresOverlayOpacity' } overlay opacity (0-255)
      %input{ :type => 'number', :name => 'departuresOverlayOpacity', :value => $settings[:departuresOverlayOpacity] }
      %br
      
    %fieldset
      %legend switching cameras
      %label{ :for => 'switchingCameraInterval' } camera interval
      %input{ :type => 'number', :name => 'switchingCameraInterval', :value => $settings[:switchingCameraInterval] }
      
    %fieldset
      %legend zooming
      %label{ :for => 'zoomCameraInterval' } camera interval
      %input{ :type => 'number', :name => 'zoomCameraInterval', :value => $settings[:zoomCameraInterval] }
      
    %br
    %input{ :type => 'submit', :value => 'apply' }
    
%p
  %form{ :action => '/record' }
    %input{ :type => 'number', :name => 'frames', :value => 200 }
    frames
    %input{ :type => 'submit', :value => 'record' }
    
%p
  %a{ :href => 'fish' } fish
  %a{ :href => 'input.mov' } input.mov
  %a{ :href => 'output.mov' } output.mov
%p
  last heartbeat: 
  = $last_heartbeat ? "#{sprintf("%0.2f", Time.now.to_f - $last_heartbeat.to_f)} seconds ago" : 'none'
  %br/
  uptime:
  = uptime.to_i
  seconds
  = "(#{sprintf("%0.2f", uptime/60/60)} hours)"
  %br/
  shutdown time:
  = $shutdown_time

%p
  %a{ :href => '/reboot'} reboot!
  
%p
  %form{ :action => '/upload', :method => :post, :enctype => 'multipart/form-data' }
    %input{ :type => 'file', :name => 'code' }
    %input{ :type => 'submit', :value => 'upload new code' }
