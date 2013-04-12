require "minitest/spec"
require "minitest/autorun"
require "socket"

require File.join(File.dirname(__FILE__), "..", "lib", "carrier-pigeon")

PRIVATE_MESSAGE = <<"EXPECTED"
NICK foo
USER foo 0 * :foo
PRIVMSG #test :test
QUIT :quit
EXPECTED

NOTICE = <<"EXPECTED"
NICK foo
USER foo 0 * :foo
NOTICE #test :test
QUIT :quit
EXPECTED

JOIN = <<"EXPECTED"
NICK foo
USER foo 0 * :foo
JOIN #test
PRIVMSG #test :test
QUIT :quit
EXPECTED

PONG = <<"EXPECTED"
NICK foo
USER foo 0 * :foo
PONG :dummy
PRIVMSG #test :test
QUIT :quit
EXPECTED

JOIN_PASSWORD = <<"EXPECTED"
NICK foo
USER foo 0 * :foo
JOIN #test bar
PRIVMSG #test :test
QUIT :quit
EXPECTED

NICKSERV_PASSWORD = <<"EXPECTED"
NICK foo
USER foo 0 * :foo
PRIVMSG NICKSERV :IDENTIFY bar
PRIVMSG #test :test
QUIT :quit
EXPECTED

describe CarrierPigeon do
  before do
    @server_received = ""
    @tcp_server = TCPServer.new(16667)
    Thread.new do
      socket = @tcp_server.accept
      server_messages.each { |msg| socket.puts msg }
      while line = socket.gets
        @server_received << line
        socket.close if line =~ /:quit/
      end
    end
  end

  after do
    @tcp_server.close
    sleep 1
  end

  describe "with server reply" do
    let :server_messages do
      [
        ":dummy 001 foo :Welcome to the Internet Relay Network",
        ":dummy 002 foo :Your host is dummy",
        ":dummy 003 foo :This server was created now",
        ":dummy 004 foo dummy"
      ]
    end

    it "can send a private message to an irc channel" do
      CarrierPigeon.send(
        :uri => "irc://foo@localhost:16667/#test",
        :message => "test"
      )
      @server_received.must_equal(PRIVATE_MESSAGE)
    end

    it "can send a notice to an irc channel" do
      CarrierPigeon.send(
        :uri => "irc://foo@localhost:16667/#test",
        :message => "test",
        :notice => true
      )
      @server_received.must_equal(NOTICE)
    end

    it "can join an irc channel and send a private message" do
      CarrierPigeon.send(
        :uri => "irc://foo@localhost:16667/#test",
        :message => "test",
        :join => true
      )
      @server_received.must_equal(JOIN)
    end

    it "can join an irc channel with a password and send a private message" do
      CarrierPigeon.send(
        :uri => "irc://foo@localhost:16667/#test",
        :message => "test",
        :channel_password => "bar",
        :join => true
      )
      @server_received.must_equal(JOIN_PASSWORD)
    end

    it "can identify with nickserv and send a private message to an irc channel" do
      CarrierPigeon.send(
        :uri => "irc://foo@localhost:16667/#test",
        :message => "test",
        :nickserv_password => "bar"
      )
      @server_received.must_equal(NICKSERV_PASSWORD)
    end

    it "must be provided an irc uri" do
      lambda {
        CarrierPigeon.send(:message => "test")
      }.must_raise RuntimeError
    end

    it "must be provided an irc message" do
      lambda {
        CarrierPigeon.send(:uri => "irc://foo@localhost:16667/#test")
      }.must_raise RuntimeError
    end
  end

  describe "with server PING before initial reply" do
    let :server_messages do
      [
        "PING :dummy",
        ":dummy 001 foo :Welcome to the Internet Relay Network",
        ":dummy 002 foo :Your host is dummy",
        ":dummy 003 foo :This server was created now",
        ":dummy 004 foo dummy"
      ]
    end

    it "must reply with PONG" do
      CarrierPigeon.send(
        :uri => "irc://foo@localhost:16667/#test",
        :message => "test"
      )
      @server_received.must_equal(PONG)
    end
  end
end
