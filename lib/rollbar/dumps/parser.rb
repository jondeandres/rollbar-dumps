# Copyright 2009 Martin Carpenter. All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:

#    1. Redistributions of source code must retain the above copyright notice, this list of
#       conditions and the following disclaimer.

#    2. Redistributions in binary form must reproduce the above copyright notice, this list
#       of conditions and the following disclaimer in the documentation and/or other materials
#       provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY Martin Carpenter ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Martin Carpenter OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of Martin Carpenter.

require 'treetop'
require 'rollbar/dumps/stackframe'
# Treetop parser classes for GDB MI responses.

module Rollbar
  module Dumps
    # Base class: a generic response is a asynchronous notification or a response
    # to a command.
    class GenericResponse < Treetop::Runtime::SyntaxNode

      # We should set instance variables in the constructor, but the treetop
      # labels (eg _oob_records) which are actually instance methods do not
      # appear to be available in the constructor. Presumably these are
      # added to each object after instantiation, hence the nasty exception
      # handling below.

      # Return true if this is a response to a GDB command.
      # See also #notification?
      def command_response?
        is_a? CommandResponse
      end

      # Return true if this is an asynchronous notification.
      # See also #command_response?
      def notification?
        is_a? Notification
      end

      # Return true if this response is a notification that contains an
      # async record indicating that a breakpoint was hit.
      def breakpoint_hit?
        exec_oob = oob_records(:exec).first
        exec_oob.results[:reason] == 'breakpoint-hit' &&
          exec_oob.record_class == :stopped
      end

      # Return true if this response is a notification that contains an
      # async record indicating that the subordinate exited normally.
      def exit?
        exec_oob = oob_records(:exec).first
        reason = exec_oob.results[:reason]
        [ 'exited', 'exited-normally' ].include?(reason) &&
          exec_oob.record_class == :stopped
      end

      # Return true if this response is a notification that contains an
      # async record indicating that the subordinate received a signal.
      def signal?
        exec_oob = oob_records(:exec).first
        exec_oob.results[:reason] == 'signal-received' &&
          exec_oob.record_class == :stopped
      end

      # Return the array of out-of-band records associated with this response
      # of the given type (:exec, :status, :notify, :console, :log or :target).
      # Although the GDB/MI specification permits more than one record of a
      # given type in a response we assume this won't happen. A RuntimeError
      # will be raised if it does occur.
      def oob_records(record_type=nil)
        @oob_records ||= begin
                           _oob_records.elements
                         rescue NameError # _oob_records not defined
                           []
                         end
        if record_type
          selected = @oob_records.select { |oob| oob.record_type == record_type }
          raise RuntimeError, 'Did not expected more than one record' if selected.size > 1
          selected
        else
          @oob_records
        end
      end

      # Return the class of the result record in this response, if any.
      def result_class
        @result_class ||= begin
                            _result_record.record_class
                          rescue NameError # _result_record not defined
                            nil
                          end
      end

      # Return the result record associated with this response, if any.
      def result_record
        @result_record ||= begin
                             _result_record
                           rescue NameError # _result_record not defined
                             nil
                           end
      end

      alias to_s text_value

      # Pretty printer.
      def pretty_print(pp)
        pp.object_address_group(self) do
          pp.text "\n"
          pp.text "@result_record="
          pp.pp result_record
          pp.text "\n"
          pp.text "@oob_records="
          pp.pp oob_records
        end
      end

    end

    # A generic command response (initial, final or standard).
    class CommandResponse < GenericResponse

      # Syntactic sugar for the result of this command (eg :done, :running).
      alias result result_class

      # Returns the message string of this command response.
      def message
        results[:msg]
      end

      def results
        result_record.results
      end

    end

    # The initial response sent upon connection, contains neither result nor
    # OOB records.
    class InitialResponse < CommandResponse ; end

    # A GDB MI command response is composed of zero or more out-of-band records
    # and a single result record.
    class Response < CommandResponse ; end

    # The final response sent upon quit.
    class FinalResponse < CommandResponse

      # We don't get a result record for quit, so we override the constructor
      # to fake a result class of :exit to agree with the MI specification.
      def initialize(text, range, parsetree)
        @result_class = :exit
      end

    end

    # An asynchronous notification is composed solely of out-of-band records.
    class Notification < GenericResponse ; end

    # A generic record class to represent result or OOB records.
    class GenericRecord < Treetop::Runtime::SyntaxNode

      # Pretty printer.
      def pretty_print(pp)
        pp.object_address_group(self) do
          pp.text " @record_class="
          pp.pp record_class
          pp.text ", @token="
          pp.pp token
          pp.text ", @results="
          pp.pp results
        end
      end

      # Return the class of this GDB result as a symbol (eg :done).
      def record_class
        @record_class ||= _record_class.text_value.to_sym
      end

      # Return the results string (string of comma-separated name-value pairs)
      # as a hash.
      def results
        @results ||= _results.elements.inject({}) { |h,r| h.merge!({ r._result.name => r._result.value }) }
      end

      # Return the optional token (integer) associated with this record.
      def token
        value = _token.text_value
        value == '' ? nil : value.to_i
      end

      alias to_s text_value

    end

    # An generic OOB asynchronous record.
    class AsyncRecord < GenericRecord ; end

    class AsyncExecRecord < AsyncRecord

      # Return a symbol representing the type of record: :exec.
      def record_type ; :exec end

    end

    # An OOB asynchronous status record.
    class AsyncStatusRecord < AsyncRecord

      # Return a symbol representing the type of record: :status.
      def record_type ; :status end

    end

    # An OOB asynchronous notify record.
    class AsyncNotifyRecord < AsyncRecord

      # Return a symbol representing the type of record: :notify.
      def record_type ; :notify end

    end

    # An generic OOB stream record.
    class StreamRecord < GenericRecord

      # Stream records have no class so this method returns nil.
      def record_class ; nil ; end

      # Stream records have a string result.
      def results
        @results ||= _results.text_value
      end

    end

    # An OOB stream console record.
    class StreamConsoleRecord < StreamRecord

      # Return a symbol representing the type of record: :console.
      def record_type ; :console end

    end

    # An OOB stream target record.
    class StreamTargetRecord < StreamRecord

      # Return a symbol representing the type of record: :target.
      def record_type ; :target end

    end

    # An OOB stream log record.
    class StreamLogRecord < StreamRecord

      # Return a symbol representing the type of record: :log.
      def record_type ; :log end

    end

    # A result record.
    class ResultRecord < GenericRecord

      # Return a symbol representing the type of record: :result.
      def record_type ; :result end

    end

    # A result name-value pair.
    class Result < Treetop::Runtime::SyntaxNode

      # Initialize a Result object as a (nil,nil) name value pair (this is
      # mostly to stop Test::Unit whining).
      def initialize(text, range, parsetree)
        @name, @value = nil, nil
        super
      end

      # Return the (symbolized) name of this result. Dashes are converted to
      # underscores.
      def name
        @name ||= _name.symbolize
      end

      # Return the value of this result as the data structure parsed from the tree.
      def value
        return @value if @value
        @value = _value.to_data_structure
        case self.name
        when :addr
          @value = @value.to_i(16)
        when :enabled
          @value = @value == 'y' ? true : false
        when :frame
          @value = Rollbar::Dumps::Stackframe.new(@value)
        when :bkptno, :exit_code, :number, :thread_id, :times
          @value = @value.to_i
        end
        @value
      end

      # Convert this result (name-value pair) to a single-key hash.
      def to_data_structure
        { self.name => self.value }
      end

      # Pretty printer.
      def pretty_print(pp)
        pp.object_address_group(self) do
          pp.text " @name="
          pp.pp name
          pp.text ", @value="
          pp.pp value
        end
      end

    end

    # The name component of a Result.
    class Name < Treetop::Runtime::SyntaxNode

      # Convert the name to a symbol so that it may be used as a hash key.
      def symbolize
        text_value.gsub(/-/, '_').to_sym
      end

    end

    # The value component of a Result.
    class Value < Treetop::Runtime::SyntaxNode

      private

      def result_elements_to_hash(elts=elements)
        hash = {}
        return hash if elts.nil? || elts.empty?
        elts.each do |elt|
          case elt
          when Result
            hash[elt.name] = elt.value
          else
            hash.merge!(result_elements_to_hash(elt.elements))
          end
        end
        hash
      end

      def value_elements_to_array(elts=elements)
        array = []
        return array if elts.nil? || elts.empty?
        elts.each do |elt|
          case elt
          when Value, Result
            array << elt.to_data_structure
          else
            array += value_elements_to_array(elt.elements)
          end
        end
        array
      end

    end

    # String constant.
    class Const < Value

      # A string constant is mapped to a String and enclosing quotes
      # are removed.
      def to_data_structure
        _unquoted_c_string.text_value
      end

    end

    # A list of name-value pair results.
    class Tuple < Value

      # A tuple is mapped to an hash. Keys are sanitized and symbolized.
      def to_data_structure
        result_elements_to_hash
      end

    end

    # A (possibly heterogenous) list of items of type Value or Result.
    class List < Value

      # A list of values is mapped to an array.
      def to_data_structure
        value_elements_to_array
      end

    end

    # Class to represent punctuation (discarded): []{},
    class Punctuation < Treetop::Runtime::SyntaxNode ; end
  end
end
