require 'rollbar/dumps/gdb'

module Rollbar
  module Dumps
    class Builder
      attr_reader :proxy

      def initialize(proxy)
        @proxy = proxy
      end

      def to_h
        initial_response = proxy.start
        frames = build_frames
        klass, message = extract_klass_and_message(initial_response, frames)

        {
          'access_token' => Configuration.access_token,
          'data' => {
            'timestamp' => Time.now.to_i,
            'environment' => 'development',
            'level' => 'error',
            'language' => 'c',
            'server' => {
              'host' => Socket.gethostname
            },
            'notifier' => {
              'name' => 'rollbar-dumps',
              'version' => Rollbar::Dumps::VERSION
            },
            'body' => {
              'trace' => {
                'frames' => frames,
                'exception' => {
                  'class' => klass,
                  'message' => message
                }
              }
            }
          }
        }
      end

      private

      def extract_klass_and_message(response, frames)
        error_match = response.to_s.match(/Program terminated with signal (.+), (.*)\./)

        klass = error_match[1]
        message = "#{error_match[2]} (#{frames[-1][:filename]})"

        [klass, message]
      end

      def build_frames
        depth = proxy.stack_info_depth.results[:depth].to_i

        (depth - 1).downto(0).to_enum.map do |frame_n|
          proxy.stack_select_frame(frame_n)
          frame = proxy.stack_frame_info.results[:frame]
          locals = extract_locals
          args = extract_args(frame_n)

          {
            :lineno => frame.line,
            :filename => frame.file,
            :method => frame.func,
            :locals => locals,
            :args => args
          }
        end
      end

      def extract_locals
        proxy.stack_list_locals.results[:locals].reduce({}) do |acc, l|
          name = l[:name]
          value = l[:value]

          acc[name] = value

          acc
        end
      end

      def extract_args(frame_n)
        args_list = proxy.stack_list_arguments(frame_n, frame_n).results[:stack_args][0][:frame].args

        args_list.map { |arg| arg[:value] }
      end
    end
  end
end
