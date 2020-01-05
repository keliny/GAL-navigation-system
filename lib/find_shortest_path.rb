class Find_shortest_path
  def initialize(visualGraph, startId, endId)
    @visualGraph = visualGraph
    @startId = startId
    @endId = endId
    @edgesWithLength = []
    fillEdges
    @distances = {}
    initializeD
    @n = [@startId]

    @visitedNodes = []
  end

  def find
    # find the shortest route
    # dijkstr
    @distances[@startId][:travelTime] = 0
    @visitedNodes << @startId
    until @distances.include? (Float::INFINITY) do
      adjacentVerticesToCheck = []
      @n.each do |n|
        # find adjacent nodes
        adjacentVerticesV1, adjacentVerticesV2 = getNeighbors(n) # these are actually edges

        # update distances
        adjacentVerticesV1.each do |adjacent|
          if @distances[adjacent[:originalEdge].v1.id][:travelTime] == Float::INFINITY
            vertex = @distances[adjacent[:originalEdge].v1.id]
            originalVertex = @distances[n]

            vertex[:travelTime] = originalVertex[:travelTime] + adjacent[:travelTime]
            vertex[:path] = Marshal.load(Marshal.dump(originalVertex[:path]))
            vertex[:path] << n
          else
            originalTime = @distances[adjacent[:originalEdge].v1.id][:travelTime]
            newTime = adjacent[:travelTime] + @distances[n][:travelTime]
            if newTime > originalTime
              vertex = @distances[adjacent[:originalEdge].v1.id]
              originalVertex = @distances[n]

              vertex[:travelTime] += adjacent[:travelTime]
              vertex[:path] = Marshal.load(Marshal.dump(originalVertex[:path]))
              vertex[:path] << n
            end
          end
          adjacentVerticesToCheck << {:id => adjacent[:originalEdge].v1.id, :distance => @distances[adjacent[:originalEdge].v1.id][:travelTime]} unless (adjacentVerticesToCheck.select { |x| x[@distances[adjacent[:originalEdge].v1.id]] }).length != 0
        end
        adjacentVerticesV2.each do |adjacent|
          if @distances[adjacent[:originalEdge].v2.id][:travelTime] == Float::INFINITY
            vertex = @distances[adjacent[:originalEdge].v2.id]
            originalVertex = @distances[n]

            vertex[:travelTime] = @distances[n][:travelTime] + adjacent[:travelTime]
            vertex[:path] == Marshal.load(Marshal.dump(originalVertex[:path]))
            vertex[:path] << n
          else
            originalTime = @distances[adjacent[:originalEdge].v2.id][:travelTime]
            newTime = adjacent[:travelTime] + @distances[n][:travelTime]
            if newTime > originalTime
              vertex = @distances[adjacent[:originalEdge].v2.id]
              originalVertex = @distances[n]

              vertex[:travelTime] += adjacent[:travelTime]
              vertex[:path] = Marshal.load(Marshal.dump(originalVertex[:path]))
              vertex[:path] << n
            end
          end
          adjacentVerticesToCheck << {:id => adjacent[:originalEdge].v2.id, :distance => @distances[adjacent[:originalEdge].v2.id][:travelTime]} unless (adjacentVerticesToCheck.select { |x| x[@distances[adjacent[:originalEdge].v2.id]] }).length != 0
        end

      end
      # get the shortest one
      adjacentVerticesToCheck.sort_by! { |x| x[:distance] }
      adjacentVerticesToCheck.select! { |x| x[:distance] == adjacentVerticesToCheck[0][:distance] } # gives us array with same minimal values

      # move values from n in to visisetd collection
      @n.length.times do
        @visitedNodes << @n.shift
      end

      # move the new values to @n
      adjacentVerticesToCheck.each do |newValue|
        @n << newValue[:id]
      end

    end


    puts 'hi'
  end

  def getNeighbors(vertexId)
    adjacentVerticesV1 = []
    adjacentVerticesV2 = []
    @edgesWithLength.each do |edge|
      if edge[:originalEdge].v1.id == vertexId && (!@visitedNodes.include? (edge[:originalEdge].v2.id))
        adjacentVerticesV2 << edge
      elsif edge[:originalEdge].v2.id == vertexId && (!@visitedNodes.include? (edge[:originalEdge].v1.id))
        adjacentVerticesV1 << edge
      end
    end

    return adjacentVerticesV1, adjacentVerticesV2
  end

  def initializeD
    @visualGraph.visual_vertices.each do |vertex|
      @distances[vertex[0].to_s] = {:travelTime => Float::INFINITY, :path => []}
    end
  end

  def fillEdges
    # new hash of edges with their length
    @visualGraph.visual_edges.each do |edge|
      modifiedEdge = {}
      modifiedEdge[:originalEdge] = edge
      modifiedEdge[:maxSpeed] = edge.edge.max_speed
      distance = calculateDistance([edge.v1.lat.to_f, edge.v1.lon.to_f], [edge.v2.lat.to_f, edge.v2.lon.to_f])
      modifiedEdge[:length] = distance > 0 ? distance / 1000 : distance / (-1000)

      # travel time in seconds
      modifiedEdge[:travelTime] = modifiedEdge[:length] / modifiedEdge[:maxSpeed] * 60 * 60

      @edgesWithLength << modifiedEdge
    end
  end

  def calculateDistance(loc1, loc2)
    rad_per_deg = Math::PI / 180 # PI / 180
    rkm = 6371 # Earth radius in kilometers
    rm = rkm * 1000 # Radius in meters

    dlat_rad = (loc2[0] - loc1[0]) * rad_per_deg # Delta, converted to rad
    dlon_rad = (loc2[1] - loc1[1]) * rad_per_deg

    lat1_rad, lon1_rad = loc1.map { |i| i * rad_per_deg }
    lat2_rad, lon2_rad = loc2.map { |i| i * rad_per_deg }

    a = Math.sin(dlat_rad / 2) ** 2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2) ** 2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1 - a))

    rm * c # Delta in meters
  end

end
