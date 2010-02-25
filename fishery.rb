require 'rubygems'
require 'sinatra'
require 'haml'
require 'osc'

OscClient = OSC::UDPSocket.new

get '/' do
  haml :index
end

get '/start' do
  cmd :run
  redirect '/'
end

get '/stop' do
  cmd :stop
  redirect '/'
end

get '/click' do
  osc :click
  redirect '/'
end

def cmd(action)
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
%a{ :href => '/start' } start
%a{ :href => '/stop' } stop
%a{ :href => '/click' } click