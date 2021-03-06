require "log4r"
require "log4r/configurator"
require "colorize"
module Saw
  module Logger
    LOG_LEVELS = [:Footprint, :Debug, :Info, :Summary, :Warn, :Error, :Fatal]
    DEFAULT_LEVEL = :Summary
    DEFAULT_OPTS = {'color' => true,'trace' => false, 'log_level' => DEFAULT_LEVEL, 'silent' => false, 'label' => false}
    LOG_COLORS = [:light_blue,:cyan, :green, :white, :yellow, :light_red, :red]
    LOG_FILE_FORMAT = "%d [%9l] %m"
    include Log4r
    def self.find_level(level)
      return level if level.kind_of?(Numeric)
      corrected_level = level.to_s.capitalize.to_sym
      raise ArgumentError.new("No level defined for: #{level.class}.#{level}") unless LOG_LEVELS.include?(corrected_level)
      LOG_LEVELS.index(corrected_level) + 1
    end

    
    def self.logger
      @@logger
    end

    def self.setup_logger(in_opts = {})
      opts = DEFAULT_OPTS.merge(in_opts)
      opts['log_level_num'] = find_level(opts['loglevel'])
      opts['console_level_num'] = opts['silent'] ? FATAL : opts['log_level_num']
      Configurator.custom_levels(*LOG_LEVELS)
      Log4r::Logger.global.level = ALL
      @@logger = Log4r::Logger.new('logger')
      @@logger.trace = opts['trace']
      @@logger.info(opts)
      @@logger.add StdoutOutputter.new('stdout', :formatter=>SawFormatter, :level => opts['console_level_num'])
      @@logger.outputters[0].formatter.color = opts['color']
      if opts['filename']
        my_format = opts['trace'] ? LOG_FILE_FORMAT + " #From: %T" : LOG_FILE_FORMAT
        @@logger.add FileOutputter.new('logfile', :formatter=>Log4r::PatternFormatter.new(:pattern=>my_format),:filename => opts['filename'], :level => opts['log_level_num'])
      end
      @@opts = opts
      @@logger.footprint "finished logger setup"
      @@logger
    end

    class SawFormatter <  Log4r::Formatter

      attr_accessor :color, :label
      @@basicformat = "%*s "

      def initialize(hash={})
        @depth = (hash[:depth] or hash['depth'] or 7).to_i
        self.color = hash[:color] or hash['color'] or true
      end

      def format(event)
        event_color = Saw::Logger::LOG_COLORS[event.level - 1]
        buff = @label ? sprintf(@@basicformat, Log4r::MaxLevelLength, Log4r::LNAMES[event.level]) : ""
        buff << format_object(event.data)
        buff << (event.tracer.nil? ? "" : "#from: #{event.tracer[0]}")
        buff << "\n"
        self.color ? buff.colorize(event_color) : buff
      end

      # Formats data according to its class:
      #
      # String::     Prints it out as normal.
      # Exception::  Produces output similar to command-line exceptions.
      # Object::     Prints the type of object, then the output of
      #              +inspect+. An example -- Array: [1, 2, 3]

      def format_object(obj)
        if obj.kind_of? Exception
          return "Caught #{obj.class}: #{obj.message}\n\t" +\
                 obj.backtrace[0...@depth].join("\n\t")
        elsif obj.kind_of? String
          return obj
        else # inspect the object
          return "#{obj.class}: #{obj.inspect}"
        end
      end

#      def format(event)
#        buff = "The level is #{event.level} and has "
#        buff += "name '#{Log4r::LNAMES[event.level]}'\n"
#        buff += "The logger is '#{event.name}' "
#        buff += "and the data type is #{event.data.class}\n"
#        buff += "Let's inspect the data:\n"
#        buff += event.data.inspect + "\n"
#        buff += "We were called at #{event.tracer[0]}\n\n"
#      end
    end

  end
end
