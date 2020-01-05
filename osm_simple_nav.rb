require_relative 'lib/graph_loader';
require_relative 'process_logger';
require_relative 'lib/component_getter';
require_relative 'lib/Cli';
require_relative 'lib/find_shortest_path';

# Class representing simple navigation based on OpenStreetMap project
class OSMSimpleNav

  # Creates an instance of navigation. No input file is specified in this moment.
  def initialize
    # register
    @load_cmds_list = ['--load', '--load-comp']
    @actions_list = ['--export', '--show-nodes', '--midist']
    @id_start
    @id_end
    @lat_start
    @lon_start
    @lat_stop
    @lon_stop

    @usage_text = <<-END.gsub(/^ {6}/, '')
	  	Usage:\truby osm_simple_nav.rb <load_command> <input.IN> <action_command> <output.OUT> 
	  	\tLoad commands: 
	  	\t\t --load ... load map from file <input.IN>, IN can be ['DOT']
	  	\tAction commands: 
	  	\t\t --export ... export graph into file <output.OUT>, OUT can be ['PDF','PNG','DOT']
    END
  end

  # Prints text specifying its usage
  def usage
    puts @usage_text
  end

  # Command line handling
  def process_args
    # not enough parameters - at least load command, input file and action command must be given
    unless ARGV.length >= 3
      puts "Not enough parameters!"
      puts usage
      exit 1
    end

    # read load command, input file and action command
    @load_cmd = ARGV.shift
    unless @load_cmds_list.include?(@load_cmd)
      puts "Load command not registred!"
      puts usage
      exit 1
    end
    @map_file = ARGV.shift
    unless File.file?(@map_file)
      puts "File #{@map_file} does not exist!"
      puts usage
      exit 1
    end
    @operation = ARGV.shift
    unless @actions_list.include?(@operation)
      puts "Action command not registred!"
      puts usage
      exit 1
    end

    # possibly load other parameters of the action
    if @operation == '--export'
    end

    # --load-comp <input_map.IN> --show-nodes <id_start> <id_stop> <exported_map.OUT>
    if @operation == '--show-nodes'
      if ARGV.length == 0
        # ruby osm_simple_nav.rb --load-comp <input_map.IN> --show-nodes
        # console interface
      elsif ARGV.length == 3
        @id_start = ARGV.shift
        @id_end = ARGV.shift
        # load output file
        @out_file = ARGV.shift
      elsif ARGV.length == 1
        #  # load output file
        @out_file = ARGV.shift
      elsif ARGV.length == 5
        @id_start = ARGV.shift
        @id_end = ARGV.shift

        # load output file
        @out_file = ARGV.shift
      end
    end


  end

  # Determine type of file given by +file_name+ as suffix.
  #
  # @return [String]
  def file_type(file_name)
    return file_name[file_name.rindex(".") + 1, file_name.size]
  end

  # Specify log name to be used to log processing information.
  def prepare_log
    ProcessLogger.construct('log/logfile.log')
  end

  # Load graph from OSM file. This methods loads graph and create +Graph+ as well as +VisualGraph+ instances.
  def load_graph
    graph_loader = GraphLoader.new(@map_file, @highway_attributes)
    @graph, @visual_graph = graph_loader.load_graph()
  end

  # method for getting the largest component
  def get_component
    component_getter = ComponentGetter.new()
    #@graph, @visual_graph = component_getter.get_component(@graph, @visual_graph)
    component_getter.get_component(@graph, @visual_graph)
  end

  # Load graph from Graphviz file. This methods loads graph and create +Graph+ as well as +VisualGraph+ instances.
  def import_graph
    graph_loader = GraphLoader.new(@map_file, @highway_attributes)
    @graph, @visual_graph = graph_loader.load_graph_viz
  end

  def run_interface
    cli = Cli.new(@visual_graph)
    @id_start, @id_end = cli.run

    run_with_ids
  end

  def run_with_ids
    # do the magic
    pathFinder = Find_shortest_path.new(@visual_graph, @id_start, @id_end)
    pathFinder.find

    # check if export file is defined
    if @out_file != nil
      # export to a file
    end
  end

  def run_with_lon_and_lat(lat_start, lon_start, lat_end, lon_end)

  end

  def midist

  end

  # Run navigation according to arguments from command line
  def run
    # prepare log and read command line arguments
    prepare_log
    process_args

    # load graph - action depends on last suffix
    #@highway_attributes = ['residential', 'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'unclassified']
    @highway_attributes = ['residential', 'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'unclassified']
    #@highway_attributes = ['residential']
    if file_type(@map_file) == "osm" or file_type(@map_file) == "xml" then
      load_graph
    elsif file_type(@map_file) == "dot" or file_type(@map_file) == "gv" then
      import_graph
    else
      puts "Imput file type not recognized!"
      usage
    end

    if @load_cmd == '--load-comp'
      get_component
    end


    # perform the operation
    case @operation
    when '--export'
      @visual_graph.export_graphviz(@out_file)
      return
    when '--show-nodes'
      if @out_file == nil
        run_interface
      elsif @id_start != nil
        run_with_ids
      elsif @lon_start != nil
        run_with_lon_and_lat
      end
      return
    when '--midist'
      midist
    else
      usage
      exit 1
    end

  end
end

osm_simple_nav = OSMSimpleNav.new
osm_simple_nav.run
