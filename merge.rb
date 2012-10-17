require 'rubygems'
require 'bundler/setup'

require 'optparse'
require 'json'
require 'uri'
require 'logger'
require 'pp'
require 'benchmark'
require 'nokogiri'

# This class is the main application class
#
# This class creates the Redis cache that is used when checking
# URLs for exemptions.
#
# Author::  Tim Rupp    (mailto:caphrim007@gmail.com)
class LspMerge
    attr_accessor :options

    def initialize
        @version = '1.0'
        @logger = Logger.new(STDOUT)

        @input = []
        @output = 'UserPatterns.xml.new'

        @noop = false
        @proper = false
    end

    def parse(args)
        # Parse all of the options available to the script.
        #
        # Options are specified in the order that they appear
        # when outputting the help for the script to the screen
        opts = OptionParser.new do |opts|
            opts.banner = "Usage: #{File.basename($0)} [options]"

            opts.separator ""
            opts.separator "Merge Options:"

            opts.on('--input INPUT', 'Comma separated list of files to use as input. Files are merged in the order they are listed') do |arg|
                @input = arg.split(',')
            end
            opts.on('--output FILENAME', 'Filename to write the merged output to (default: UserPatterns.xml.new)') do |arg|
                @output = arg
            end
            opts.on('--proper', 'Specify that proper XML merging be done. This can take a long time for large files (default: false)') do |arg|
                @proper = true
            end

            opts.separator ""
            opts.separator "General Options:"
            opts.on('-h', '--help', 'Show this message') do |arg|
                puts opts
                exit
            end
            opts.on('--version', 'Show version') do
                puts @version
                exit
            end

            opts.separator ""
            opts.separator "Debugging Options:"

            opts.on('--noop', 'Do not perform any actions, only print out what would be done') do |arg|
                @noop = true
            end
        end

        opts.parse!(args)
    end

    def run_proper()
        if @noop
            @logger.debug "Noop: Opening #{@output} file for writing"
        else
            @logger.debug "Opening #{@output} file for writing"
            io = File.open(@output, 'w')

            io.write '<?xml version="1.0"?>'
            io.write '<ArrayOfPattern xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
        end

        @logger.debug "Merging #{@input.length} files"
        @input.each do | merge |
            @logger.debug "Opening #{merge} file"
            current_io = File.open(merge)

            @logger.debug "Parsing XML from #{merge}. This may take a while if the file is large"
            @current_doc = Nokogiri::XML::Reader(current_io)

            @current_doc.each do | node |
                if node.name == "Pattern" && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
                    if @noop
                        @logger.debug 'Noop: Would have written a <Pattern> block'
                    else
                        io.write node.outer_xml
                    end
                end
            end

            current_io.close()
        end

        if @noop
            @logger.debug 'Noop: Wrapping up XML file. Closing file handlers'
        else
            io.write '</ArrayOfPattern>'
            io.close()
        end
    end

    def run_fast()
        in_xml = false

        if @noop
            @logger.debug "Noop: Opening #{@output} file for writing"
        else
            @logger.debug "Opening #{@output} file for writing"
            io = File.open(@output, 'w')

            io.write '<?xml version="1.0"?>'
            io.write '<ArrayOfPattern xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
        end

        @logger.debug "Merging #{@input.length} files"

        @input.each do | merge |
            @logger.debug "Opening #{merge} file"
            current_io = File.open(merge)

            current_io.each_line do | line |
                line = line.strip

                if line == '<Pattern>'
                    in_xml = true
                    if @noop
                        @logger.debug 'Noop: Entering a <Pattern> block'
                    end
                end

                if in_xml and line == '</Pattern>'
                    in_xml = false

                    if @noop
                        @logger.debug 'Noop: Leaving a <Pattern> block'
                    else
                        io.write line
                    end
                end

                if in_xml
                    if not @noop
                        io.write line
                    end
                end
            end

            current_io.close()
        end

        if @noop
            @logger.debug 'Noop: Wrapping up XML file. Closing file handlers'
        else
            io.write '</ArrayOfPattern>'
            io.close()
        end
    end

    def run()
        tmpInput = []
        @logger.debug "Will write output to #{@output}"

        if @input.empty?
            @logger.error "You need to specify at least one input file"
        end

        @input.each do | input |
            if File.readable? input
                tmpInput.push input
            else
                @logger.error "#{input} was not readable. Skipping it"
            end
        end

        if tmpInput.empty?
            @logger.error 'You specified input files, but none of them were readable'
            return
        else
            @input = tmpInput
        end

        if @proper
            self.run_proper
        else
            self.run_fast
        end
    end
end

# Doing this check allows us to include this file in test frameworks
# so that we can check to make sure the classes work properly without
# having to create special modules that must be distributed with this
# script
if __FILE__ == $0
    time = Benchmark.realtime do
        obj = LspMerge.new

        obj.parse(ARGV)
        obj.run()
    end

    puts "Time elapsed #{time} seconds"
end
