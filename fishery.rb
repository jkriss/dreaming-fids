require 'rubygems'
require 'sinatra'
require 'haml'
require 'osc'
require 'open-uri'

OscClient = OSC::UDPSocket.new

# HOSTS = %w(jklabs-mbp.local thing1.local thing2.local)
HOSTS = %w(thing1.local thing2.local)
LAZY_COMPUTER = 'thing2.local'
# LAZY_COMPUTER = 'jklabs-mbp.local'
HEARTBEAT_URL = "http://google.com"
# HEARTBEAT_URL = "http://sanjoseartcloud.org/heartbeat/?installation_id=[id]"
HEARTBEAT_DELAY = 60 # in seconds
SERVER_PORT = 4567
# HEARTBEAT_DELAY = 60 # in seconds

@@settings = {}
@@hostname = nil

set :public, Proc.new { File.join(root,'dreaming','mugshots') }
# set :settings_path, Proc.new { File.join(root,'dreaming','settings.txt') }
SETTINGS_PATH = 'dreaming/settings.txt'

def read_settings
  if File.exists?(SETTINGS_PATH)
    File.open(SETTINGS_PATH).read.strip.split('&').each { |line| vals = line.split("="); @@settings[vals.first.intern] = vals[1] if vals.size > 1 }
    puts "loaded #{@@settings.inspect}"
  end
end

def hostname
  @@hostname ||= `hostname`.strip
end

def other_hosts
  HOSTS.reject{ |h| h == hostname }
end

# start heartbeat
configure do
  
  @@last_heartbeat = nil
  
  if hostname == LAZY_COMPUTER
    
  
    puts "  - about to start heartbeat thread"
    heartbeat = Thread.new do
      while true do
        puts "pinging #{other_hosts.inspect}"
        other_hosts.each do |h|
          url = "http://#{h}:#{SERVER_PORT}/heartbeat"
          puts "- about to ping #{url}"
          begin
            open(url)
          rescue Exception => e
            puts "ERROR: #{e} URL: #{url}"
          end
          puts "- ping #{url} at #{Time.now}"
        end
        sleep(HEARTBEAT_DELAY)
      end
    end
    
  else
  
    puts "  - registering status listeners"
    
  end
end

get '/' do
  read_settings
  @settings = @@settings
  puts "current settings: #{@settings.inspect}"
  haml :index
end

get '/fish' do
  haml :fishies
end

get '/heartbeat' do
  if hostname != LAZY_COMPUTER
    puts "got local ping, sending heartbeat to #{HEARTBEAT_URL}"
    @@last_heartbeat = Time.now
    open(HEARTBEAT_URL)
  end
  redirect '/'
end

get '/restart_server' do
  `./fishcontrol server:stop && ./fishcontrol server:start`
end

get '/reboot' do
  echo '/reboot'
  `./fishcontrol reboot`
end

post '/upload' do
  puts params[:code][:tempfile].path
  `cd #{File.dirname(__FILE__)} && tar xf #{params[:code][:tempfile].path}`
  File.delete(params[:code][:tempfile].path)
  redirect '/'
end

get '/open' do
  cmd :open
  echo '/open'
  redirect '/'
end

get '/run' do
  cmd :run
  echo '/run'
  redirect '/'
end

get '/stop' do
  cmd :stop
  echo '/stop'
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

get '/behaviors/:id' do
  osc :behavior, 'i', params[:id].to_i
  redirect '/'
end

get '/test/input' do
  osc :showRawInput, 's', 'ptthbt'
  redirect '/'
end

get '/settings' do
  puts params.inspect
  params[:showBlobs] ||= false
  params[:cycleBehaviors] ||= false
  @@settings = params
  osc :setSettings, 's', params.keys.collect{ |k| "#{k}=#{params[k]}" }.join("&")
  redirect '/'
end

get '/record' do
  osc :record, 'i', params[:frames].to_i
  redirect '/'
end

def echo(request_path)
  return if params[:echo] == 'false'
  other_hosts.each do |h|
    url = "http://#{h}:#{SERVER_PORT}#{request_path}?echo=false"
    puts "requesting #{url}"
    begin
      open url
    rescue Exception => e
      puts "error loading url: #{e}"
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
  puts "sending #{m.inspect}"
  OscClient.send m, 0, "230.0.0.1", 7447
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
      line-height: 1.6em;
      display: inline-block;
    }
  </style>

%p
  %a{ :href => '/open' } open
  %a{ :href => '/run' } run
  %a{ :href => '/stop' } stop
  %a{ :href => '/click' } click
  %a{ :href => '/fullscreen' } fullscreen
  %a{ :href => '/restart_server' } restart web server

%p
  %a{ :href => '/behaviors/0'} mugshots
  %a{ :href => '/behaviors/1'} departures
  %a{ :href => '/behaviors/2'} cameras
  %a{ :href => '/behaviors/3'} switching cameras
  %a{ :href => '/behaviors/4'} zooming

%p
  %a{ :href => '/test/input'} raw input
  
%p
  %form{ :action => '/settings' }
  
    %fieldset
      %legend general
      %label{ :for => 'cycleBehaviors' } Cycle behaviors
      %input#cycleBehaviors{ :type => 'checkbox', :name => 'cycleBehaviors', :value => 'cycleBehaviors', :checked => @@settings[:cycleBehaviors]}
      %br
      %label{ :for => 'cycleLength' } Cycle length
      %input{ :type => 'number', :name => 'cycleLength', :value => @@settings[:cycleLength] }

    
    %fieldset
      %legend mugshots
      %label{ :for => 'showBlobs' } Show blobs
      %input#showBlobs{ :type => 'checkbox', :name => 'showBlobs', :value => 'showBlobs', :checked => @@settings[:showBlobs]}
      %br
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
  = @@last_heartbeat ? "#{sprintf("%0.2f", Time.now.to_f - @@last_heartbeat.to_f)} seconds ago" : 'none'

%p
  %a{ :href => '/reboot'} reboot!
  
%p
  %form{ :action => '/upload', :method => :post, :enctype => 'multipart/form-data' }
    %input{ :type => 'file', :name => 'code' }
    %input{ :type => 'submit', :value => 'upload new code' }
