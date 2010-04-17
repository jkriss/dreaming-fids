require 'rubygems'
require 'sinatra'
require 'haml'
require 'osc'
require 'open-uri'

OscClient = OSC::UDPSocket.new

HOSTS = %w(jklabs-mbp.local thing1.local thing2.local)
LAZY_COMPUTER = 'thing2.local'
# LAZY_COMPUTER = 'jklabs-mbp.local'
HEARTBEAT_URL = "http://google.com"
# HEARTBEAT_URL = "http://sanjoseartcloud.org/heartbeat/?installation_id=[id]"
HEARTBEAT_DELAY = 60 # in seconds
SERVER_PORT = 4567
# HEARTBEAT_DELAY = 60 # in seconds

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
  haml :index
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
  </style>

%p
  %a{ :href => '/open' } open
  %a{ :href => '/run' } run
  %a{ :href => '/stop' } stop
  %a{ :href => '/click' } click
  %a{ :href => '/fullscreen' } fullscreen
  %a{ :href => '/restart_server' } restart server

%p
  %a{ :href => '/behaviors/0'} mugshots
  %a{ :href => '/behaviors/1'} departures

%p
  last heartbeat: 
  = @@last_heartbeat ? "#{sprintf("%0.2f", Time.now.to_f - @@last_heartbeat.to_f)} seconds ago" : 'none'
