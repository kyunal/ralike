require "levenshtein"
require "option_parser"
require "./mappings"  # local include

# some major top level definitions
VERSION = "0.1.0"
REDDIT = "https://reddit.com"
alias Match = NamedTuple(origin: String, reasons: Array(String), references: Array(Source)) 

# define input and config which should be set by parser
file_input = file_config = file_output = ""

# may be overriden as parser option
all = false
limit = 5_u64 # UInt64 to prevent negatives and give headroom

# parse CLI using OptionParser
options_parser = OptionParser.parse do |parser|
  parser.banner = "Usage: ralike -i INPUT -c CONFIG [OPTIONS]"

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.on "-v", "--version", "Show version" do
    puts "ralike version #{VERSION}"
    exit
  end

  parser.on "-a", "--all", "Show all results (do not exclude names that are equal)" { all = true }
  parser.on "-i INPUT", "--input INPUT", "Select input data\t(required)" { |file| file_input = file }
  parser.on "-c CONFIG", "--config CONFIG", "Select config file\t(required)" { |file| file_config = file }
  parser.on "-o OUTPUT", "--output OUTPUT", "Select output file\t(optional)" { |file| file_output = file }
  parser.on "-l LIMIT", "--length LIMIT", "Limit amount of references to display (default: 5)" { |num| limit = num.to_u64 }
end

# validate required inputs before proceeding
if file_input.empty? || file_config.empty? 
  STDERR.puts "ERROR: Invalid arguments!"
  STDERR.puts options_parser
  exit(1)
end

# parse config & use exception handling to provide feedback
puts "Reading & parsing config.."
begin
  config = Hash(String, ConfigEntry).from_json(File.read(file_config))
rescue ex
  STDERR.puts "ERROR: Unable to read/parse config! Reason: #{ex.message}"
  exit(1)
end
puts "Parsed #{config.size} config #{config.size == 1 ? "entry" : "entries"}"

# parse input data & use exception handling to provide feedback
puts "Reading & parsing input data.."
begin
  data = Response.from_json(File.read(file_input))
rescue ex
  STDERR.puts "ERROR: Unable to read/parse input data! Reason: #{ex.message}"
  exit(1)
end
puts "Parsed #{data.hits.hits.size}/#{data.hits.total} #{data.hits.hits.size == 1 ? "entry" : "entries"}"

# prepare our output storage
output = Hash(String, Match).new

# iterate over each data entry
data.hits.hits.each do |hit|
  name = hit._source.author
  reasons = [] of String

  # try to match every data entry with our config entries
  config.each do |entry|
    alike = entry[0]
    settings = entry[1]

    # ignore current entry if -a isn't set
    next if name == alike && !all

    # check distance using Levenshtein edit-based string similarity
    distance = settings.distance
    if !distance.nil?
      score = Levenshtein.distance(alike, name)
      if (0..distance).includes?(score)
        reasons << "Matched distance (#{score}/#{distance})"
      end
    end

    # check regex
    pattern = settings.pattern
    unless pattern.nil?
      unless name.index(Regex.new(pattern)).nil?
        reasons << "Matched pattern '#{pattern}'"
      end
    end

    # ignore if no reason was given aka nothing was matched
    next if reasons.empty?

    # see if there is an existing entry we can connect to, else create a new key object
    if output[name]?.nil?
      output[name] = {origin: alike, reasons: reasons, references: [hit._source]}
    else
      # do not add this again if the reflink is already existent, pushshift re-supplies objects based on modifications etc
      # TODO: improve check, it's kinda rushed
      output[name][:references] << hit._source unless output[name][:references].find {|i| i.permalink == hit._source.permalink}
    end
  end
end

# build final string output using optimized String.build
final = String.build do |io|
  output.each_with_index do |tup, index|
    # static header line
    io << "Match:\t\t" << tup[0] << "\nURL:\t\t" << REDDIT << "/u/" << tup[0] << "\nMatches:\t" << tup[1][:origin]

    # properly use singular / plural for both reasons and references
    single = tup[1][:reasons].size == 1 
    io << "\nReason" << (single ? "" : "s") << ":"
    tup[1][:reasons].each_with_index do |reason, index|
      io << (index > 0 ? "\n" : "") << ((single || index > 0) ? "\t\t" : "\t")
      io << index+1 << ". " unless single
      io << reason
    end

    # only do references if we are even supposed to
    if limit > 0
      single = !(tup[1][:references].size > 1 && limit > 1)
      io << "\nReference" << (single ? "" : "s") << ":\t"
      tup[1][:references].each_with_index do |ref, index|
        # break if this element is beyond the given limit (-l)
        break if index > limit-1

        io << (index > 0 ? "\n\t\t" : "") << (single ? "" : ">> ") << REDDIT << ref.permalink
      end
    end

    # only append separating newlines if this isnt the last object
    io << "\n\n" if output.size-1 > index
  end
end

# output to stdout
puts final

# if a file_output was given, write final there and notify the user
if !file_output.empty?
  begin 
    File.write(file_output, final)
  rescue ex
    STDERR.puts "ERROR: Saving results to #{file_output} failed! Reason: #{ex.message}"
    exit(1)
  end
  puts "\nSaved results to #{file_output}"
end