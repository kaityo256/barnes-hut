require 'rubygems'
require 'cairo'

class Node
  def initialize(size, x, y)
    @size = size
    @x = x
    @y = y
    @myparticle = -1
    @nodes = []
  end

  def add_sub(i, q)
    hs = @size*0.5
    ix = ((q[i].x - @x)/hs).to_i
    iy = ((q[i].y - @y)/hs).to_i
    id = ix + iy * 2
    @nodes[id].add(i, q)
  end

  def add(i, q)
    if @nodes.size != 0
      add_sub(i, q)
    elsif @myparticle !=-1
      hs = @size*0.5
      @nodes.push Node.new(hs, @x, @y)
      @nodes.push Node.new(hs, @x+hs, @y)
      @nodes.push Node.new(hs, @x, @y+hs)
      @nodes.push Node.new(hs, @x+hs, @y+hs)
      add_sub(@myparticle, q)
      add_sub(i, q)
      @myparticle = -1
    else
      @myparticle = i
    end
  end

end

class Node
  def draw(context)
    return if @nodes.size == 0
    context.set_source_rgb(0, 0, 0)
    hs = @size*0.5
    context.move_to(@x + hs, @y)
    context.line_to(@x + hs, @y+@size)
    context.move_to(@x , @y + hs)
    context.line_to(@x + @size, @y+hs)
    context.stroke
    @nodes.each do |t|
      t.draw(context)
    end
  end
end

def save_png(filename, size, q, root)
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
  root.draw(context) if root !=nil
  surface.write_to_png(filename)
end

Particle = Struct.new(:x, :y)
srand(2)
L = 256.0
q = []
10.times do
  x = L*rand
  y = L*rand
  q.push Particle.new(x, y)
end

root = Node.new(L, 0.0, 0.0)
q.size.times do |i|
  root.add(i, q)
end

save_png("initial.png", L, q, nil)
save_png("barnes-hut.png", L, q, root)
