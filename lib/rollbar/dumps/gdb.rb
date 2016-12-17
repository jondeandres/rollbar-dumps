require 'treetop'
require 'rollbar/dumps/parser'
require 'rollbar/dumps/gdb_response_parser'


module Rollbar
  module Dumps
    class Gdb
      attr_reader :gdb
      attr_reader :pid
      attr_reader :interpreter
      attr_reader :binary
      attr_reader :core
      attr_reader :parser

      def initialize(options)
        @interpreter = options[:interpreter] || 'mi2'
        @binary = options[:binary]
        @core = options[:core]
        @parser = GdbResponseParser.new
      end

      def start
        @gdb = IO.popen("gdb -n -q -i #{interpreter} #{binary} #{core}", 'w+')

        receive
      end

      def close
        gdb.close
      end

      def command(cmd)
        gdb.puts(cmd)

        receive
      end

      private

      def receive
        loop do
          # block until response with 1s timeout
          result = IO.select([gdb], nil, nil, 1)

          break unless result.nil? || result[0].empty?
        end

        lines = []

        loop do
          line = gdb.readline
          lines << line

          break if ["(gdb) \n"].include?(line)
        end

        response = lines.join

        parser.parse(response)
      end
    end
  end
end
