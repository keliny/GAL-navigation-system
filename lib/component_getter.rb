require_relative 'visual_graph'

class ComponentGetter
  @visitedEdges = []
  @visitedVertices = []
  @component

  def initialize
    @visitedEdges = []
    @visitedVertices = []
  end

  def get_component(graph, visualGraph)
    components = {}
    buffer = []

    c = -1
    graph.vertices.each do |vertex|
      # ignore already visited edges
      unless @visitedVertices.include?(vertex[1])
        # add component and edge to visited
        c += 1
        components[c] = []
        buffer << vertex[1]

        until buffer.length == 0 do
          v = buffer.shift
          unless @visitedVertices.include? v
            @visitedVertices << v
            components[c] << v
            adjacentVertices = process_vertex(v, graph)
            adjacentVertices.each do |x|
              buffer << x unless @visitedVertices.include? x
            end
          end
        end

      end
    end

    graph, visualGraph = get_max_component(graph, visualGraph, components)

    return graph, visualGraph
  end

  def get_max_component(graph, visualGraph, components)
    components = components.sort.reverse
    # save the main component
    @component = components.shift

    # delete all other objects
    graph.vertices.each do |vert|
      graph.vertices.delete(vert[0]) unless @component[1].include? vert[1]
    end

    graph.edges.each do |edg|
      graph.edges.delete(edg) unless ((@component[1].include? edg.v1) || (@component[1].include? edg.v2))
    end

    #visualGraph.graph = graph

    visualGraph.visual_vertices.each do |visualVer|
      visualGraph.visual_vertices.delete(visualVer[0]) unless @component[1].include? visualVer[1].vertex
    end

    visualGraph.visual_edges.each do |visualEdg|
      visualGraph.visual_edges.delete(visualEdg) unless ((@component[1].include? visualEdg.v1.vertex) || (@component[1].include? visualEdg.v2.vertex))
    end

    visualGraphNew = VisualGraph.new(graph, visualGraph.visual_vertices, visualGraph.visual_edges, visualGraph.bounds)
    return graph, visualGraphNew
  end

  def process_vertex(vertex, graph)
    # get all related edges
    edgesV1 = graph.edges.select {|e| e.v1.id == vertex.id}
    edgesV2 = graph.edges.select {|e| e.v2.id == vertex.id}
    # collect all related vertices
    adjacentVertices = edgesV1.collect {|e| e.v2}

    edgesV2.collect { |e|  e.v1 }.each do |ve|
      adjacentVertices << ve
    end

    adjacentVertices
  end
end