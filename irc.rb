require 'socket'

class Irc

  def initialize(opts={})
    opts[:port]    ||= 6667
    opts[:server]  ||= 'irc.freenode.net'
    opts[:nick]    ||= Socket.gethostname + '_' + rand(1000..9999)
    opts[:channel] ||= '#OfficeBlaster'
    @opts = opts
    @socket = TCPSocket.open(opts[:server], opts[:port])
    say "NICK IrcBot"
    say "USER ircbot 0 * IrcBot"
    say "JOIN #{@channel}"
    say_to_chan "#{1.chr}ACTION is here to help#{1.chr}"
  end

  def say(msg)
    @socket.puts msg
  end

  def say_to_chan(msg)
    say "PRIVMSG #{@opts[:channel]} :#{msg}"
  end

  def run
    until @socket.eof? do
      msg = @socket.gets
      if msg.match(/^PING :(.*)$/)
        say "PONG #{$~[1]}"
      elsif msg.match(/PRIVMSG #{@opts[:channel]} :(.*)$/)
        content = $~[1]
        #put matchers here
        if content.match()
          say_to_chan('your response')
        end
      end
    end
  end

  def quit
    say "PART #{@opts[:channel]} :OUT"
    say 'QUIT'
  end
end

bot = Irc.new

trap("INT"){ bot.quit }

bot.run
