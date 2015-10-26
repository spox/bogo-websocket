require 'openssl'
require 'websocket'
require 'bogo-websocket'

module Bogo
  module Websocket

    # Simple websocket client
    class Client

      include Bogo::Lazy
      include Bogo::Memoization

      attribute :destination, URI, :required => true, :coerce => lambda{|v| URI.parse(v) }
      attribute :path, String
      attribute :params, Hash, :default => {}
      attribute :headers, Hash, :default => {}
      attribute :ssl_context, OpenSSL::SSL::SSLContext
      attribute :ssl_key, String
      attribute :ssl_certificate, String

      attribute :on_connect, Proc, :default => proc{}
      attribute :on_disconnect, Proc, :default => proc{}
      attribute :on_error, Proc, :default => proc{|error|}
      attribute :on_message, Proc, :default => proc{|message|}

      # @return [TCPSocket, OpenSSL::SSL::SSLSocket]
      attr_reader :connection
      # @return [Thread]
      attr_reader :container
      # @return [WebSocket::Frame::Incoming::Client]
      attr_reader :client
      # @return [WebSocket::Handshake::Client]
      attr_reader :handshake
      # @return [TrueClass, FalseClass]
      attr_reader :die
      # @return [IO]
      attr_reader :control_r
      # @return [IO]
      attr_reader :control_w

      # Create a new websocket client
      #
      # @return [self]
      def initialize(args={})
        load_data(args)
        @control_r, @control_w = IO.pipe
        @die = false
        setup_connection
        perform_handshake
        @lock = Mutex.new
        @container = start!
      end

      # Write to socket
      #
      # @param line [String]
      def write(line)
        transmit(line, :text)
      end

      # Close the connection
      def close
        connection.close
        @die = true
        control_w.write 'closed'
        container.join
      end

      # Start the reader
      def start!
        unless(@container)
          @container = Thread.new do
            until(die || connection.closed?)
              begin
                unless(die || connection.closed?)
                  client << connection.read_nonblock(2046)
                  if(message = client.next)
                    handle_message(message)
                  end
                end
              rescue IO::WaitReadable, EOFError, Errno::ECONNRESET
                unless(die || connection.closed?)
                  IO.select([connection, control_r])
                  retry
                end
              rescue => error
                on_error.call(error)
                raise
              end
            end
            @connection = nil
          end
        end
      end

      # Handle an incoming message
      #
      # @param message [WebSocket::Frame::Incoming::Client]
      def handle_message(message)
        case message.type
        when :binary, :text
          on_message.call(message.data)
        when :ping
          transmit(message.data, :pong)
        when :close
          connection.close
          on_disconnect.call
        end
      end

      # Send data to socket
      #
      # @param data [String]
      # @param type [Symbol]
      def transmit(data, type)
        message = WebSocket::Frame::Outgoing::Client.new(
          :version => handshake.version,
          :data => data,
          :type => type
        )
        result = connection.write message.to_s
        connection.flush
        result
      end

      # Setup the handshake and perform handshake with remote connection
      #
      # @return [TrueClass]
      def perform_handshake
        port = destination.port || destination.scheme == 'wss' ? 443 : 80
        @handshake = WebSocket::Handshake::Client.new(
          :host => destination.host,
          :port => port,
          :secure => destination.scheme == 'wss',
          :path => path,
          :query => URI.encode_www_form(params),
          :headers => headers
        )
        connection.write handshake.to_s
        reply = ''
        until(handshake.finished?)
          reply << connection.read(1)
          if(reply.index(/\r\n\r\n/m))
            handshake << reply
            reply = ''
          end
        end
        unless(handshake.valid?)
          raise ArgumentError.new 'Invalid handshake. Failed to connect!'
        end
        @client = WebSocket::Frame::Incoming::Client.new(:version => handshake.version)
        true
      end

      # @return [TCPSocket, OpenSSL::SSL::SSLSocket]
      def setup_connection
        socket = TCPSocket.new(destination.host, destination.port)
        if(destination.scheme == 'wss')
          socket = OpenSSL::SSL::SSLSocket.new(socket, build_ssl_context)
          socket.connect
        end
        @connection = socket
      end

      # @return [OpenSSL::SSL::SSLContext]
      def build_ssl_context
        if(ssl_context)
          ssl_context
        else
          ctx = OpenSSL::SSL::SSLContext.new
          if(ssl_key || ssl_certificate)
            ctx.cert = OpenSSL::X509::Certificate.new(File.read(ssl_certificate))
            ctx.key = OpenSSL::PKey::RSA.new(File.read(ssl_key))
          end
          ctx
        end
      end

    end
  end
end
