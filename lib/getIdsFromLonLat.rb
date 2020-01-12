class Get_Ids_from_lat_lon
  def initialize(visualGraph, lat_start, lat_end, lon_start, lon_end)
    @visualGraph = visualGraph
    @id_start
    @id_end
    @lat_start = lat_start
    @lon_start = lon_start
    @lat_stop = lat_end
    @lon_stop = lon_end
  end

  def GetIds
    vertices = @visualGraph.visual_vertices

    vertices.each do |vertex|
      if vertex[1].lon == @lon_start && vertex[1].lat == @lat_start
        @id_start = vertex[0]
      elsif vertex[1].lon == @lon_stop && vertex[1].lat == @lat_stop
        @id_end = vertex[0]
      end
    end

    return @id_start, @id_end
  end
end