require "ngrok/tunnel/version"
require "tempfile"

module Ngrok

  class NotFound < StandardError; end
  class FetchUrlError < StandardError; end
  class Error < StandardError; end

  class Tunnel

    class << self
      attr_reader :pid, :ngrok_url, :ngrok_url_https, :ngrok_url_tcp, :status

      def init(params = {})
        @params = {port: 3001, timeout: 10, config: '/dev/null'}.merge(params)
        @status = :stopped unless @status
      end

      def start(params = {})
        ensure_binary
        init(params)

        if stopped?
          @params[:log] = (@params[:log]) ? File.open(@params[:log], 'w+') : Tempfile.new('ngrok')
          if(@params[:config] == '/dev/null')
            command = "exec ngrok http #{@params[:port]} " + ngrok_exec_params
          else
            command = "exec ngrok start --all " + ngrok_exec_params
          end
          @pid = spawn(command)
          at_exit { Ngrok::Tunnel.stop }
          @status = :running
          fetch_urls
        end

        @ngrok_url
      end

      def stop
        if running?
          Process.kill(9, @pid)
          @ngrok_url = @ngrok_url_https = @pid = nil
          @status = :stopped
        end
        @status
      end

      def running?
        @status == :running
      end

      def stopped?
        @status == :stopped
      end

      def port
        @params[:port]
      end

      def log
        @params[:log]
      end

      def subdomain
        @params[:subdomain]
      end

      def authtoken
        @params[:authtoken]
      end

      def inherited(subclass)
        init
      end

      private

      def ngrok_exec_params
        exec_params = "-log stdout -log-level debug "
        exec_params << "-authtoken #{@params[:authtoken]} " if @params[:authtoken]
        exec_params << "-subdomain #{@params[:subdomain]} " if @params[:subdomain]
        exec_params << "-config #{@params[:config]} "
        exec_params << "> #{@params[:log].path}"
      end

      def fetch_urls
        @params[:timeout].times do
          log_content = @params[:log].read
          result = log_content.scan(/URL:(.+)\sProto:(http|https|tcp)\s/)
          if !result.empty?
            result = Hash[*result.flatten].invert
            @ngrok_url = result['http']
            @ngrok_url_https = result['https']
            @ngrok_url_tcp = result['tcp'] if result['tcp']
            return @ngrok_url if @ngrok_url
          end

          error = log_content.scan(/msg="command failed" err="([^"]+)"/).flatten
          unless error.empty?
            self.stop
            raise Ngrok::Error, error.first
          end

          sleep 1
          @params[:log].rewind
        end
        raise FetchUrlError, "Unable to fetch external url"
        @ngrok_url
      end

      def ensure_binary
        `ngrok version`
      rescue Errno::ENOENT
        raise Ngrok::NotFound, "Ngrok binary not found"
      end
    end

    init

  end
end
