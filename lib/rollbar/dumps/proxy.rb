require 'rollbar/dumps/gdb'

module Rollbar
  module Dumps
    class Proxy
      attr_reader :gdb

      def initialize(options)
        @gdb = Gdb.new(options)
      end

      def start
        gdb.start
      end

      def stop
        gdb.close
      end

      def set_absolute_filenames
        gdb.command('set filename-display absolute')
      end

      def stack_list_frames
        gdb.command('-stack-list-frames')
      end

      def stack_frame_info
        gdb.command('-stack-info-frame')
      end

      def stack_info_depth
        gdb.command('-stack-info-depth')
      end

      def stack_select_frame(frame)
        gdb.command("-stack-select-frame #{frame}")
      end

      def stack_list_locals
        gdb.command("-stack-list-locals 1")
      end

      def stack_list_arguments(low_frame, high_frame)
        gdb.command("-stack-list-arguments 1 #{low_frame} #{high_frame}")
      end
    end
  end
end
