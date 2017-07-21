module Ragu

function saveJsonGraph(json_name="graph.json")

  source_network = readSource("")
  json_network = makeSourceJson(source_network)

  write(json_name, json_network)

end


function readSource(folder="")
  #cd(folder)
  # Read directory:
  ind = readdir()
  # Regex to find all .m files:
  reg = map(x->match(r"\w*(?=\.m$)", x), ind)
  # Array of filenames i.e. function names:
  filenames = convert(Array{String,1}, loadMatchArray(reg))
  # Create the network dictionary:
  net = Dict{String,Array{String,1}}()
  for x in filenames
    tmp_read = readlines(x*".m")
    tmp_match = map(x->match(r"\w*(?=\w*\()", x), tmp_read)
    #tmp_match_array = loadMatchArray(tmp_match)
    tmp_match_array = intersect(loadMatchArray(tmp_match), filenames)
    push!(net, x => tmp_match_array)
  end
  #print(net)
  # Add network weights:
  wnet = Dict()
  for x in collect(keys(net))
    #x = "resolkw"
    tmp_node_weigth = 0.5 + length(net[x])
    tmp_edges_raw = collect(net[x])
    x_node = (x, tmp_node_weigth)
    tmp_edges = setdiff(unique(tmp_edges_raw), [x])
    if length(tmp_edges) == 0
      tmp_node_weigth += 0
      x_edges = [(nothing, 0)]
    else
      tmp_node_weigth += length(tmp_edges_raw)
      x_edges = map(z1->(z1, length(
                    filter(z2->isequal(z2,z1),tmp_edges_raw))
                    ), tmp_edges)
   end
   push!(wnet, (x_node => x_edges))
  end

  return wnet

end

function makeSourceJson(wnet=[])

  tmp_nodes = collect(keys(wnet))
  tmp_jnodes = []
  tmp_jedges = []
  tmp_id_store = Dict()

  i = 1
  j = 1
  # Create random positions for nodes:
  x_i = zeros(length(tmp_nodes))
  y_i = zeros(length(tmp_nodes))
  rand!(x_i)
  rand!(y_i)
  x_i *= 20
  y_i *= 20
  # Unroll the Dict into JSON
  for x in tmp_nodes
    # JSON for single node:
    push!(tmp_jnodes,
          "{ \"id\": \"n$(i)\",
              \"label\": \"$(x[1])\",
              \"x\": $(x_i[i]),
              \"y\": $(y_i[i]),
              \"size\": \"$(x[2])\"
          }")
    push!(tmp_id_store, (x[1] => "n$(i)"))
    # Add comma:
    if i < length(tmp_nodes)
      push!(tmp_jnodes, ",\n")
    end
    i += 1
  end
  i = 1
  for x in tmp_nodes
    # JSON for edges of node x:
    for y in wnet[x]
      # Make sure edges aren't empty and that there are no duplicates:
      #ord = findin(collect(map(z->z[1], tmp_nodes)), [x[1]])
      #println(y[1])
      if y[1] != nothing
        ord = sum(findin(collect(map(z->z[1], tmp_nodes)), [x[1]]))
        #println("$ord - $(x) - $(y)")
        if ord >= i
          push!(tmp_jedges,
                "{ \"id\": \"$(j)\",
                   \"source\": \"$(tmp_id_store[x[1]])\",
                   \"target\": \"$(tmp_id_store[y[1]])\"
                }")
          push!(tmp_jedges, ",\n")
        end
      end
      j += 1
    end
    i += 1
  end
  # Pop the last element of tmp_jnodes:
  tmp_jedges = tmp_jedges[1:end-1]

  json_ = " { \"nodes\": [$(prod(tmp_jnodes))],\n
             \"edges\": [$(prod(tmp_jedges))]
          } "

  return json_

end

function loadMatchArray(matchStruct)

  T = []
  for x in matchStruct
    if x != nothing
      #print("$(x.match) ")
      #print("$(typeof(x.match)) ")
      push!(T, x.match)
    end
  end

  return T

end

end
