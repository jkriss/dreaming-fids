require 'rubygems'
require 'sinatra'
require 'haml'
require 'osc'
require 'open-uri'

OscClient = OSC::UDPSocket.new

HOSTS = %w(jklabs-mbp.local thing1.local thing2.local)

get '/' do
  haml :index
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

def echo(request_path)
  return if params[:echo] == 'false'
  other_hosts.each do |h|
    url = "http://#{h}:9393#{request_path}?echo=false"
    puts "requesting #{url}"
    begin
      open url
    rescue Exception => e
      puts "error loading url: #{e}"
    end
  end
end

def hostname
  @@hostname ||= `hostname`.strip
end

def other_hosts
  HOSTS.reject{ |h| h == hostname }
end

def cmd(action)
  # this will need to run on both machines
  # just use ssh?
  `./fishcontrol #{action}`
end

def osc(method)
  m = OSC::Message.new("/fish/in/#{method}", "s", "hi")
  puts "sending #{m.inspect}"
  OscClient.send m, 0, "230.0.0.1", 7447
end

__END__

@@ layout
%html
  = yield

@@ index
%a{ :href => '/open' } open
%a{ :href => '/run' } run
%a{ :href => '/stop' } stop
%a{ :href => '/click' } click
%a{ :href => '/fullscreen' } fullscreen