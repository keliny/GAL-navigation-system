require_relative '../process_logger'
require 'nokogiri'
require_relative 'graph'
require_relative 'visual_graph'

# Class to load graph from various formats. Actually implemented is Graphviz formats. Future is OSM format.
class GraphLoader
	attr_reader :highway_attributes

	# Create an instance, save +filename+ and preset highway attributes
	def initialize(filename, highway_attributes)
		@filename = filename
		@highway_attributes = highway_attributes 
	end

	# Load graph from Graphviz file which was previously constructed from this application, i.e. contains necessary data.
	# File needs to contain 
	# => 1) For node its 'id', 'pos' (containing its re-computed position on graphviz space) and 'comment' containig string with comma separated lat and lon
	# => 2) Edge (instead of source and target nodes) might contains info about 'speed' and 'one_way'
	# => 3) Generaly, graph contains parametr 'bb' containing array withhou bounds of map as minlon, minlat, maxlon, maxlat
	#
	# @return [+Graph+, +VisualGraph+]
	def load_graph_viz()
		ProcessLogger.log("Loading graph from GraphViz file #{@filename}.")
		gv = GraphViz.parse(@filename)

		# aux data structures
		hash_of_vertices = {}
		list_of_edges = []
		hash_of_visual_vertices = {}
		list_of_visual_edges = []		

		# process vertices
		ProcessLogger.log("Processing vertices")
		gv.node_count.times { |node_index|
			node = gv.get_node_at_index(node_index)
			vid = node.id

			v = Vertex.new(vid) unless hash_of_vertices.has_key?(vid)
			ProcessLogger.log("\t Vertex #{vid} loaded")
			hash_of_vertices[vid] = v

			geo_pos = node["comment"].to_s.delete("\"").split(",")
			pos = node["pos"].to_s.delete("\"").split(",")	
			hash_of_visual_vertices[vid] = VisualVertex.new(vid, v, geo_pos[0], geo_pos[1], pos[1], pos[0])
			ProcessLogger.log("\t Visual vertex #{vid} in ")
		}

		# process edges
		gv.edge_count.times { |edge_index|
			link = gv.get_edge_at_index(edge_index)
			vid_from = link.node_one.delete("\"")
			vid_to = link.node_two.delete("\"")
			speed = 50
			one_way = false
			link.each_attribute { |k,v|
				speed = v if k == "speed"
				one_way = true if k == "oneway"
			}
			e = Edge.new(vid_from, vid_to, speed, one_way)
			list_of_edges << e
			list_of_visual_edges << VisualEdge.new(e, hash_of_visual_vertices[vid_from], hash_of_visual_vertices[vid_to])
		}

		# Create Graph instance
		g = Graph.new(hash_of_vertices, list_of_edges)

		# Create VisualGraph instance
		bounds = {}
		bounds[:minlon], bounds[:minlat], bounds[:maxlon], bounds[:maxlat] = gv["bb"].to_s.delete("\"").split(",")
		vg = VisualGraph.new(g, hash_of_visual_vertices, list_of_visual_edges, bounds)

		return g, vg
	end

	# Method to load graph from OSM file and create +Graph+ and +VisualGraph+ instances from +self.filename+
	#
	# @return [+Graph+, +VisualGraph+]
	def load_graph()

		# Get bounds which are needed later
		doc = File.open(@filename) { |f| Nokogiri::XML (f) }

		# get bounds
		bounds = {}

		doc.xpath("//bounds").each do |boundsValues|
			bounds[:minlon] = boundsValues[:minlon]
			bounds[:minlat] = boundsValues[:minlat]
			bounds[:maxlon] = boundsValues[:maxlon]
			bounds[:maxlat] = boundsValues[:maxlat]
		end

		# load nodes
		vertices = {}
		visualVertices = {}
		doc.xpath("//node").each do |node|
			# this vertex
			normalVertex = Vertex.new(node[:id])
			vertices[node[:id]] = normalVertex

			# kinda confusing to have lat, lon and x, y when they have the same value
			visualVertex = VisualVertex.new(node[:id], normalVertex, node[:lat], node[:lon], node[:lat], node[:lon])
			visualVertices[node[:id]] = visualVertex
		end

		# load edges
		edgesAr = []
		visualEdgesAr = []
		v1 = nil
		skip = true
		wayCounter = 0
		wayCounter2 = 0



		doc.xpath("//way").each do |way|
			doc2 = Nokogiri::XML(way.to_s)
			# for each way check tags for highway, speed etc
			wayCounter2 = wayCounter2 + 1
			v1 = nil
			skip = true
			maxSpeed = 50
			oneWay = false

			doc2.xpath("//tag").each do |tag|
				if tag[:k] == "highway" && (@highway_attributes.include? tag[:v])
					skip = false
				end

				if tag[:k] == "maxspeed"
					maxSpeed = tag[:v].to_i
				end

				if tag[:k] == "oneway" && tag[:v] == "yes"
					oneWay = true
				end

				# Set max speed based on the tag
				if tag[:k] == "source:maxspeed"
					if tag[:v] == "CZ:motorway"
						maxSpeed = 130
					elsif tag[:v] == "CZ:trunk"
						maxSpeed = 110
					elsif tag[:v] == "CZ:rural"
						maxSpeed = 90
					elsif tag[:v] == "CZ:urban_motorway"
						maxSpeed = 80
					elsif tag[:v] == "CZ:urban_trunk"
						maxSpeed = 80
					elsif tag[:v] == "CZ:urban"
						maxSpeed = 50
					end
				end
			end

			if !skip
				wayCounter = wayCounter + 1

				doc2.xpath("//nd").each do |point|
					if v1 == nil
						v1 = point[:ref]
					else
						# create normal edge
						newEdge = {:vertex1 => v1, :vertex2 => point[:ref], :maxSpeed => maxSpeed, :oneWay => oneWay}
						edgesAr << newEdge


						# edges << Edge.new(v1, point[:ref], maxSpeed, oneWay)
						v1 = point[:ref]
					end
				end
			end
		end

		# we have all the edges eg lines. there is a lot of duplicates so reduce them!
		edgesArReduced = edgesAr.uniq

		# used is a unique hash of used vertices - we don't need points that are not being referenced by any path
		usedVertices = {}
		usedVisualVertices = {}
		edges = []
		# now put them into the array as instances of the required class Edge
		edgesArReduced.each do |edge|
			newEdgeReduced = Edge.new(vertices[edge[:vertex1]], vertices[edge[:vertex2]], edge[:maxSpeed], edge[:oneWay])

			# used vertices
			usedVertices[edge[:vertex1]] = vertices[edge[:vertex1]]
			usedVertices[edge[:vertex2]] = vertices[edge[:vertex2]]

			edges <<  newEdgeReduced # create visual edge


			visualEdge = VisualEdge.new(newEdgeReduced, visualVertices[edge[:vertex1]], visualVertices[edge[:vertex2]])
			usedVisualVertices[edge[:vertex1]] = visualVertices[edge[:vertex1]]
			usedVisualVertices[edge[:vertex2]] = visualVertices[edge[:vertex2]]

			visualEdgesAr << visualEdge
		end

		# load
		#
		# test generating the graph with the graphwiz - all seems good in the exported file
		graph = Graph.new(usedVertices, edges)
		visualGraph = VisualGraph.new(graph, usedVisualVertices, visualEdgesAr, bounds)

		# we have edges nwo find the largest component
		components = {}


		return graph, visualGraph

	end
end
