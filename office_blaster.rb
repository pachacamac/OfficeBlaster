#!/usr/bin/env ruby

require 'drb'

MUSIC_PATH = File.expand_path(File.join(File.dirname(__FILE__),'music'))
SERVERS = [
  'druby://0.0.0.0:13123', #This is your machine
  'druby://a:13123',       #..some
  'druby://b:13123',       #..other
  'druby://c:13123',       #..machines
]

class OfficeBlasterServer
  def play file
    stop if @pid
    file = File.expand_path(File.join(MUSIC_PATH, file))
    puts "playing #{file}"
    return false unless File.exists? file
    @pid = fork do
      if RUBY_PLATFORM =~ /darwin/
        exec 'afplay', file
      else
        exec 'mpg123','-T' ,'-q', file
      end
    end
  end

  def stop
    return unless @pid
    puts "stopping"
    Process.kill 'TERM', @pid
    @pid = nil
  end

  def upload name, content
    puts "receiving '#{name}'"
    path = File.expand_path(File.join(MUSIC_PATH, name))
    File.open(path,'w'){ |f| f.write content }
  end

  def list
    puts "listing"
    Dir.entries(MUSIC_PATH).reject{|e|e.start_with? '.'}.sort
  end
end

class OfficeBlasterClient
  def self.method_missing(method, *args, &block)
    @@servers ||= {}
    responses = {}
    SERVERS.each do |server|
      @@servers[server] ||= DRbObject.new(nil, server)
      begin
        responses[server] = @@servers[server].send(method, *args, &block) if @@servers[server].respond_to?(method)
      rescue
        puts $!
        @@servers[server] = nil
      end
    end
    responses
  end
end

case ARGV[0]
  when 'r', 'run'
    DRb.start_service SERVERS.first, OfficeBlasterServer.new
    puts "Server running at #{DRb.uri}"
    begin
      DRb.thread.join
    rescue Interrupt
    ensure
      DRb.stop_service
    end
  when 'p', 'play'
    OfficeBlasterClient.play ARGV[1]
  when 's', 'stop'
    OfficeBlasterClient.stop
  when 'u', 'upload'
    OfficeBlasterClient.upload File.basename(ARGV[1]), File.read(ARGV[1])
  when 'l', 'list'
    list = OfficeBlasterClient.list
    list.keys.each{|k| puts k, list[k].map{|e|"\t#{e}"}}
  else
    puts "))) OfficeBlaster (((
       Commands are:
          r|run               : start the OfficeBlaster server
          p|play <filename>   : play song
          s|stop              : stop current playback
          u|upload <filename> : upload a new file to all servers
          l|list              : get a list of remote files
    "
end

