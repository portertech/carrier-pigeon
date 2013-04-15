require "addressable/uri"
require "socket"
require "openssl"

class CarrierPigeon

  def initialize(options={})
    [:host, :port, :nick, :channel].each do |option|
      raise "You must provide an IRC #{option}" unless options.has_key?(option)
    end
    tcp_socket = TCPSocket.new(options[:host], options[:port])
    if options[:ssl]
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
      @socket.sync = true
      @socket.sync_close = true
      @socket.connect
    else
      @socket = tcp_socket
    end
    sendln "PASS #{options[:password]}" if options[:password]
    sendln "NICK #{options[:nick]}"
    sendln "USER #{options[:nick]} 0 * :#{options[:nick]}"
    while line = @socket.gets
      case line
      when /00[1-4] #{Regexp.escape(options[:nick])}/
        break
      when /^PING :(.+)$/i
        sendln "PONG :#{$1}"
      end
    end
    sendln options[:nickserv_command] if options[:nickserv_command]
    if options[:join]
      join = "JOIN #{options[:channel]}"
      join += " #{options[:channel_password]}" if options[:channel_password]
      sendln join
    end
  end

  def message(channel, message, notice = false)
    command = notice ? "NOTICE" : "PRIVMSG"
    sendln "#{command} #{channel} :#{message}"
  end

  def die
    sendln "QUIT :quit"
    @socket.gets until @socket.eof?
    @socket.close
  end

  def self.send(options={})
    raise "You must supply a valid IRC URI" unless options[:uri]
    raise "You must supply a message" unless options[:message]
    uri = Addressable::URI.parse(options[:uri])
    options[:host] = uri.host
    options[:port] = uri.port || 6667
    options[:nick] = uri.user
    options[:password] = uri.password
    options[:channel] = "#" + uri.fragment
    if options[:nickserv_password]
      options[:nickserv_command] ||=
        "PRIVMSG NICKSERV :IDENTIFY #{options[:nickserv_password]}"
    end
    pigeon = new(options)
    pigeon.message(options[:channel], options[:message], options[:notice])
    pigeon.die
  end

  private

  def sendln(cmd)
    @socket.puts(cmd)
  end

end
