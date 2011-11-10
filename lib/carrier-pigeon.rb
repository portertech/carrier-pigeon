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
    sendln "JOIN #{options[:channel]} #{options[:channel_password]}" if options[:join]
  end

  def message(channel, message)
    sendln "PRIVMSG #{channel} :#{message}"
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
    options[:channel_password] = options[:channel_password]
    options[:channel] = "#" + uri.fragment
    pigeon = new(options)
    pigeon.message(options[:channel], options[:message])
    pigeon.die
  end

  private

  def sendln(cmd)
    @socket.puts(cmd)
  end

end
