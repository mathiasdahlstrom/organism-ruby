

module Organism
  
  module Source

    class SSH < Base
      
      attr_accessor :host, :user, :port, :keys, :password, :proxy_user, :proxy_port, :channels
      
      def initialize server_name, source_properties, config
        super(server_name, source_properties, config)
        @proxy_user = source_properties['proxy_user']
        @proxy_host = source_properties['proxy_host']
        @user = source_properties['user']
        @port = source_properties['port']
        @host = source_properties['host']
        @keys = source_properties['keys']
        @password = source_properties['password']
      end
      
      def init

        @channels = []

        puts "Connecting to #{host}..." if($VRB > 0 || $DBG > 0)

        session_options = { }
        session_options[:port] = @port if @port
        session_options[:keys] = @keys if @keys
        session_options[:verbose] = :debug if $DBG > 1
        session_options[:password] = @password if @password
        begin
          if @password
            session_options[:auth_methods] = [ "password","keyboard-interactive" ]
          end
          if @proxy_host && @proxy_user
            @ssh_proxy = Net::SSH::Gateway.new(@proxy_host, @proxy_user)
            @session = @ssh_proxy.ssh(@host, @user, session_options)
          else
            @session = Net::SSH.start(@host, @user, session_options)
          end
        rescue SocketError, Errno::ECONNREFUSED => e
          puts "!!! Could not connect to #{host}. Check to make sure that this is the correct url."
          puts $! if $DBG > 0
          exit
        rescue Net::SSH::AuthenticationFailed => e
          puts "!!! Could not authenticate on #{host}. Make sure you have set the username and password correctly. Or if you are using SSH keys make sure you have not set a password."
          puts $! if $DBG > 0
          exit
        end

        # FIXME: add support for multiple files (eg. write files accessor)
        do_tail(@file, @command)
        @session.process 0
      end

      def parse_line(data)
        @buffer.gsub(/\r\n/,"\n").gsub(/\n/, "\n\n").each("") do |line|

          unless line.include? "\n\n"
            @buffer = "#{line}"
            next
          end

          line.gsub!(/\n\n/, "\n")
          line.gsub!(/\n\n/, "\n")

          puts "#{host}[#{user}]: #{line}" if $DBG > 0
          
          @parser.parse(line)
          
        end

        @buffer = "" if @buffer.include? "\n"
      end

      def do_tail( file, command )
        channel = @session.open_channel do |channel|
          channel.request_pty
          @buffer = ""
          channel.on_data do |ch, data|
              @buffer << data
              parse_line(data)
          end

          channel.do_failure do |ch|
              puts 'ssh channel failed'
              ch.close
          end

          channel.on_extended_data do |ch, data|
              puts "STDERR: #{data}\n"
          end

          channel.on_close do |ch|
              puts 'ssh channel closed'
              ch[:closed] = true
          end
          
          channel.exec "#{command} #{file}"
        end
        puts "Pushing #{host}\n" if($VRB > 0 || $DBG > 0)
        @channels.push(channel)
      end
    
      def process
        @session.process 0
      end
    end
  end
end
