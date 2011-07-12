require "addressable/uri"
require "socket"
require "openssl"

class CarrierPigeon

  def initialize(server, port, nick, password, ssl)
    tcp_socket = TCPSocket.new(server, port || 6667)
    if ssl
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
      @socket.sync = true
      @socket.sync_close = true
      @socket.connect
    else
      @socket = tcp_socket
    end
    sendln "PASS #{password}" if password
    sendln "NICK #{nick}"
    sendln "USER #{nick} 0 * :#{nick}"
  end

  def message(channel, message)
    sendln "PRIVMSG #{channel} :#{message}"
  end

  def die
    @socket.close
  end

  def self.send(options={})
    raise ArgumentError unless options[:uri] && options[:message]
    uri = Addressable::URI.parse(options[:uri])
    ssl = options[:ssl] || false
    pigeon = new(uri.host, uri.port, uri.user, uri.password, ssl)
    pigeon.message("#" + uri.fragment, options[:message])
    pigeon.die
  end

  private

  def sendln(cmd)
    @socket.write("#{cmd}\r\n")
    @socket.flush
  end

end
