local map_data = {}
local map_param2_data = {}
local perlin_buffers = {}

mapgen_helper.mapgen_vm_data = function()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(map_data)
	return vm, map_data, VoxelArea:new{MinEdge=emin, MaxEdge=emax}
end

mapgen_helper.mapgen_vm_data_param2 = function()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(map_data)
	vm:get_param2_data(map_param2_data)
	return vm, map_data, map_param2_data, VoxelArea:new{MinEdge=emin, MaxEdge=emax}
end

mapgen_helper.perlin3d = function(name, minp, maxp, perlin_params)
	--minetest.debug(name..minetest.pos_to_string(minp)..minetest.pos_to_string(maxp))
	local minx = minp.x
	local minz = minp.z
	local sidelen = maxp.x - minp.x + 1 --length of a mapblock
	local chunk_lengths = {x = sidelen, y = sidelen, z = sidelen} --table of chunk edges

	perlin_buffers[name] = perlin_buffers[name] or {}
	perlin_buffers[name].nvals_perlin_buffer = perlin_buffers[name].nvals_perlin_buffer or {}
	
	perlin_buffers[name].nobj_perlin = perlin_buffers[name].nobj_perlin or minetest.get_perlin_map(perlin_params, chunk_lengths)
	local nvals_perlin = perlin_buffers[name].nobj_perlin:get_3d_map_flat(minp, perlin_buffers[name].nvals_perlin_buffer) 
	return nvals_perlin, VoxelArea:new{MinEdge=minp, MaxEdge=maxp}
end

mapgen_helper.perlin2d = function(name, minp, maxp, perlin_params)
	local minx = minp.x
	local minz = minp.z
	local sidelen = maxp.x - minp.x + 1 --length of a mapblock
	local chunk_lengths = {x = sidelen, y = sidelen, z = sidelen} --table of chunk edges

	perlin_buffers[name] = perlin_buffers[name] or {}
	perlin_buffers[name].nvals_perlin_buffer = perlin_buffers[name].nvals_perlin_buffer or {}
	
	perlin_buffers[name].nobj_perlin = perlin_buffers[name].nobj_perlin or minetest.get_perlin_map(perlin_params, chunk_lengths)
	local nvals_perlin = perlin_buffers[name].nobj_perlin:get_2d_map_flat({x=minp.x, y=minp.z}, perlin_buffers[name].nvals_perlin_buffer)
	
	return nvals_perlin
end

-- similar to iter_xyz, but iterates first along the y axis. Useful in mapgens that want to detect a vertical transition (eg, finding ground level)
function VoxelArea:iter_yxz(minx, miny, minz, maxx, maxy, maxz)
	local i = self:index(minx, miny, minz) - self.ystride
	
	local x = minx
	local y = miny - 1
	local z = minz

	return function()
		y = y + 1

		if y <= maxy then
			i = i + self.ystride
			return i, x, y, z
		end
		
		y = miny
		x = x + 1
		
		if x <= maxx then
			i = self:index(x, y, z)
			return i, x, y, z
		end
		
		x = minx
		z = z + 1
		
		if z <= maxz then
			i = self:index(x, y, z)
			return i, x, y, z
		end
	end
end

function VoxelArea:iterp_yxz(minp, maxp)
	return self:iter_yxz(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z)
end

mapgen_helper.index2dp = function(minp, maxp, x, z) 
	return x - minp.x +
		(maxp.x - minp.x + 1) -- sidelen
		*(z - minp.z)
		+ 1
end

-- Takes an index into a 3D area and returns the corresponding 2D index
-- assumes equal edge lengths
mapgen_helper.index2di = function(minp, maxp, area, vi)
	local MinEdge = area.MinEdge
	local zstride = area.zstride
	local minpx = minp.x
	i = vi - 1
	local z = math.floor(i / zstride) + MinEdge.z
	local x = math.floor((i % zstride) % area.ystride) + MinEdge.x
	return x - minpx +
		(maxp.x - minpx + 1) -- sidelen
		*(z - minp.z)
		+ 1
end