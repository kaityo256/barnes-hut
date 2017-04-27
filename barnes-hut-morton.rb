require 'rubygems'
require 'cairo'

class BHTree
	def initialize(size)
		@keyhash = Hash.new
		@size = size
	end

	def key2level(key)
		((3*key+1).bit_length+1)/2-1
	end

	def parentkey(key)
		return 0 if key == 0
		level = key2level(key)
		key = key - (4**level -  1)/3
		key = key >> 2
		key = key + (4**(level-1) -  1)/3
		key
	end

	def key2pos(key)
		x = 0.0
		y = 0.0
		level = key2level(key)
		key = key - (4**level -  1)/3
		s = @size.to_f / (2**level).to_f
		level.times do
			x = x + (key & 1)*s
			key = key >> 1
			y = y + (key & 1)*s
			key = key >> 1
			s = s * 2.0
		end
		return x,y
	end

	def add_sub(key, i, mkey, q)
		level = key2level(key)
		x, y = key2pos(key)
		s = @size.to_f / (2 ** (level+1))
		ix = ((q[i].x - x)/s).to_i
		iy = ((q[i].y - y)/s).to_i
		id = ix + iy * 2
		key = key - (4**level - 1)/3
		key = key << 2
		key = key + id
		key = key + (4**(level+1) -1)/3
		add(key, i, mkey, q)
	end

	def add(key, i, mkey, q)
		if !@keyhash.has_key?(key)
			@keyhash[key] = i
			mkey[i] = key
		elsif @keyhash[key] == -1
			add_sub(key, i, mkey, q)
		else
			j = @keyhash[key]
			@keyhash[key] = -1
			add_sub(key, j, mkey, q)
			add_sub(key, i, mkey, q)
		end

	end
end

class BHTree
	def draw(key, context)
		context.set_source_rgb(0, 0, 0)
		key = parentkey(key)
		level = key2level(key)
		hs = @size / (2**(level+1))
		x, y = key2pos(key)
		context.move_to(x + hs, y)
		context.line_to(x + hs, y + hs*2)
		context.move_to(x , y + hs)
		context.line_to(x + hs*2, y + hs)
		context.stroke
		if key !=0
			draw(key, context)
		end
	end
end

def save_png(filename, size, q, mkey, tree)
	surface = Cairo::ImageSurface.new(Cairo::FORMAT_RGB24, size, size)
	context = Cairo::Context.new(surface)
	context.set_source_rgb(1, 1, 1)
	context.rectangle(0, 0, size, size)
	context.fill
	context.set_source_rgb(0, 0, 0)
	context.rectangle(0, 0, size, size)
	context.stroke
	context.set_source_rgb(1, 0, 0)
	q.each do |qi|
		context.arc(qi.x,qi.y,2,0,2.0*Math::PI)
		context.fill
	end
	if tree!=nil
		mkey.each do |key|
			tree.draw(key,context)
		end
	end
	surface.write_to_png(filename)
end

tree = BHTree.new(256)

Particle = Struct.new(:x, :y)
srand(2)
L = 256.0
q = []
10.times do
	x = L*rand
	y = L*rand
	q.push Particle.new(x, y)
end

mkey = Array.new(q.size)

q.size.times do |i|
	tree.add(0,i,mkey,q)
end

save_png("initial.png",L, q, mkey, nil)
save_png("barnes-hut.png",L, q, mkey, tree)

