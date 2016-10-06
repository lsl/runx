class Task
  def initialize(name, doc, action)
    @name = name
    @doc = doc
    @action = action
  end

  def run(args)
    @action.call(args)
  end

  attr_accessor :name, :doc
end

class TaskManager
  def initialize
    @tasks = {}
    @message = nil
  end

  def doc(message)
    @message = message
  end

  def run(name, &block)
    @tasks[name.to_s.downcase] = Task.new(name.to_s, @message, block) 
    @message = nil
  end

  attr_accessor :tasks
end

def find_runfile
  previous = nil
  dir = Dir.pwd
  while dir != previous
    runfile = File.join(dir, 'Runfile')
    return runfile.gsub(File::SEPARATOR, File::ALT_SEPARATOR) if File.exist?(runfile)
    previous = dir
    dir = File.expand_path(File.join(dir, '..'))
  end

  return nil
end

runfile = find_runfile
if runfile.nil?
  $stderr.puts "No Runfile found."
  exit 1
end

runfile_dir = File.dirname(runfile)
Dir.chdir(runfile_dir) do
  manager = TaskManager.new
  manager.instance_eval File.read(runfile), runfile

  task = ARGV[0]
  if !task
    puts 'Commands:'
    width = manager.tasks.map { |name, task| name.length }.max
    manager.tasks.each do |name, task|
      space = ' ' * (width - name.length + 6)
      puts "  #{task.name}#{space}#{task.doc}"
    end
  else
    task = manager.tasks[task.downcase]
    if task.nil?
      puts "#{task} not found."
      exit 1
    end

    # Clear ARGV to avoid interference with `gets`:
    # http://ruby-doc.org/core-2.1.5/Kernel.html#method-i-gets
    args = ARGV[1...ARGV.length]
    ARGV.clear

    task.run(args)
  end
end