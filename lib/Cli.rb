class Cli
  def initialize(visualGraph)
    @visualGraph = visualGraph
    @startingIndexId = nil
    @endVertexId = nil
  end

  def run
    displayVertices

    while @startingIndexId == nil do
      @startingIndexId = getValue('select a starting point: ')
    end

    while @endVertexId == nil do
      @endVertexId = getValue('select an end point: ')
    end

    if @startingIndexId == @endVertexId
      puts 'Congratulations, you are where you want to be.'
      return
    end

    return @startingIndexId, @endVertexId
  end

  def getValue(message)
    puts message
    value = gets
    value = value.strip
    if @visualGraph.visual_vertices[value] == nil
      puts "wrong"
      return nil
    end
    return value
  end

  def displayVertices
    @visualGraph.visual_vertices.each_with_index  do |vertex, index|
      puts vertex[1].id + " : " + vertex[1].lat + ", " + vertex[1].lon
    end
  end
end
