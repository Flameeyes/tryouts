

class Tryouts::Drill
  
  require 'tryouts/drill/response'
  require 'tryouts/drill/sergeant/cli'
  require 'tryouts/drill/sergeant/api'
  
  class NoSergeant < RuntimeError; end
    
    # A symbol specifying the drill type. One of: :cli
  attr_reader :dtype
    # The name of the drill. This should match the name used in the dreams file. 
  attr_reader :name
    # A Proc object which contains the drill logic. 
  attr_reader :drill
  
    # A Sergeant object which executes the drill
  attr_reader :sergeant
    # A Dream object
  attr_reader :dream
    # A Reality object
  attr_reader :reality
      
  def initialize(name, dtype, *drill_args, &drill)
    @name, @dtype, @drill = name, dtype, drill
    @sergeant = hire_sergeant *drill_args
    # For CLI drills, a block takes precedence over inline args. 
    drill_args = [] if dtype == :cli && drill.is_a?(Proc)
  end
  
  def hire_sergeant(*drill_args)
    if @dtype == :cli
      Tryouts::Drill::Sergeant::CLI.new(*drill_args)
    elsif @dtype == :api
      Tryouts::Drill::Sergeant::API.new(*drill_args)
    else
      raise NoSergeant, "What is #{@dtype}?"
    end
  end
  
  def run(context=nil)
    context ||= Class.new
    begin
      print Tryouts::DRILL_MSG % @name
      @reality = @sergeant.run @drill, context
      process_reality
    rescue => ex
      @reality = Tryouts::Drill::Reality.new
      @reality.rcode = -2
      @reality.emsg, @reality.backtrace = ex.message, ex.backtrace
    end  
    note = @dream ? discrepency.join(', ') : 'nodream'
    puts self.success? ? "PASS" : "FAIL (#{note})"
    self.success?
  end
  
  def success?
    @dream == @reality
  end
  
  def discrepency
    diffs = []
    if @dream
      diffs << "rcode" if @dream.rcode != @reality.rcode
      diffs << "output" if @dream.output != @reality.output
      diffs << "emsg" if @dream.emsg != @reality.emsg
    end
    diffs
  end
  
  def add_dream(d)
    @dream = d if d.is_a?(Tryouts::Drill::Dream)
  end
  
  private 
  # Use the :format provided in the dream to convert the output from reality
  def process_reality
    @reality.normalize!
    return unless @dream && @dream.format
    if @dream.format.to_s == "yaml"
      @reality.output = YAML.load(@reality.output.join("\n"))
    elsif  @dream.format.to_s == "json"
      @reality.output = JSON.load(@reality.output.join("\n"))
    end
    
    if @reality.output.is_a?(Array)
      # Remove new lines from String output
      @reality.output = @reality.output.collect do |line|
        line.is_a?(String) ? line.strip : line
      end
    end
    
    #p [:process, @name, @dream.format, @reality.output]
  end
end
