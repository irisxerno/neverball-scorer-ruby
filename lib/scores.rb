require "listen"
require "psych"
require "time"

# executes `clear`
CLEAR=%x{clear}

def clear
  STDOUT.write CLEAR
end

DIFFICULTIES=["Hard", "Medium", "Easy"]

class Float
  def to_s_timer
    i = self
    hours = (i/3600).to_i
    i = i.modulo(3600)
    minutes = (i/60).to_i
    i = i.modulo(60)
    seconds = i.to_i
    dec = (i.modulo(1)*1000).to_i
    "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, dec]
  end
end

class LevelSet
  private
  def take_score(h)
    t_,c_,n_ = h.split(" ")
    return [Integer(t_)/100, Integer(c_), n_]
  end
  def get_chomp(u)
    s = u.gets("\n")
    return nil if s == nil
    return s.chomp
  end
  def parse_scores(e)
    raise unless get_chomp(e) == "version 2"
    raise unless get_chomp(e).split(" ")[0]  == "set"
    a = []
    o = []
    1.upto(2) {
      k = []
      1.upto(3) {
        k << take_score(get_chomp(e))
      }
      o << k
    }
    a << o
    loop do
      level = get_chomp(e)
      return a if level == nil
      _, st, _, path = level.split(" ")
      st_ = [:unlocked, :locked, :completed][Integer(st)]
      o = [[st_,path]]
      1.upto(3) {
        k = []
        1.upto(3) {
          k << take_score(get_chomp(e))
        }
        o << k
      }
      a << o
    end
    raise
  end
  def get_r(o)
    i = 3
    o.each { |e|
      break unless DIFFICULTIES.include? e[2]
      i -= 1
    }
    return i
  end
  def get_rank(o)
    if get_r(o) == 3
      return 1
    else
      return 0
    end
  end
  def count_stats(a)
    stats = { completed: 0, maxcompleted: 0, total: 0, maxtotal: 0, challenge: { completed: false, ranks: [], total: 0 }, levels: [] }

    0.upto(1) { |i|
      stats[:maxtotal] += 1
      r = get_rank(a[0][i])
      stats[:challenge][:ranks] << r
      stats[:challenge][:total] += r
      stats[:total] += r
    }

    stats[:maxcompleted] += 1
    if get_r(a[0][0]) > 0 or get_r(a[0][1]) > 0
      stats[:challenge][:completed] = true
      stats[:completed] += 1
    end


    a[1..].each { |e|
      ll = { state: e[0][0], ranks:[] , total: 0 }
      stats[:maxcompleted] += 1
      stats[:completed] += 1 if ll[:state] == :completed
      1.upto(3) { |i|
        stats[:maxtotal] += 1
        r = get_rank(e[i])
        ll[:ranks] << r
        stats[:total] += r
        ll[:total] += r
      }
      stats[:levels] << ll
    }
    return stats
  end
  def gen_stats()
    level = {:state=>:locked, :ranks=>[0, 0, 0], :total=>0}
    stats = {
      :completed=>0, :maxcompleted=>26, :total=>0, :maxtotal=>77,
      :challenge=>{:completed=>false, :ranks=>[0, 0], :total=>0},
      :levels=>[]
    }
    1.upto(@size) {
      stats[:levels] << level.dup
    }
    stats[:levels][0][:state] = :unlocked
    return stats
  end
  public
  attr_accessor :name, :stats
  def initialize(s, neverball_scores)
    sa = s.split(":",2)
    @name = sa[0]
    @size = 25
    @size = Integer(sa[1]) if sa.length > 1
    @neverball_scores = neverball_scores
    update
  end
  # update :: reread and count and diff
  def update()
    if File.exist?(@neverball_scores+"/#{@name}.txt") then
      f = @neverball_scores+"/#{@name}.txt"
      data = nil
      File.open(f) { |f|
        data = parse_scores(f)
      }
      stats = count_stats(data)
      File.open("example_stats.data", "w") { |f|
        f.puts(stats.inspect)
      }
      @stats = stats
    else
      @stats = gen_stats()
    end
  end
  def to_pretty_string(reverse)
    s = StringIO.new
    s.write "## #{self.name} "
    if not @stats[:challenge][:completed]
      s.puts "{ ____ }"
    else
      k = []
      ["U", "C"].each_with_index { |r,i|
        if reverse ^ (@stats[:challenge][:ranks][i] == 0)
          k << "."
        else
          k << r
        end
      }
      s.puts "{ #{'%-4.4s' % k.join(" ")} }"
    end
    0.upto(4) { |i|
      0.upto(4) { |j|
        l = @stats[:levels][i*5+j]
        if not l
          next
        end
        if l[:state] == :locked
          s.write "{ /////// }"
        elsif l[:state] == :unlocked
          s.write "{ _______ }"
        else
          k = []
          ["T", "U", "C"].each_with_index { |r,i|
            if reverse ^ (l[:ranks][i] == 0)
              k << "."
            else
              k << r
            end
          }
          s.write "{ #{'%-7.7s' % k.join(" ")} }"
        end
        if j == 4
          s.write "\n"
        else
          s.write " "
        end
      }
    }
    scm = "#{@stats[:completed]}/#{@stats[:maxcompleted]}"
    spr = "#{Integer((100.0/@stats[:maxcompleted])*@stats[:completed])}"
    tcm = "#{@stats[:total]}/#{@stats[:maxtotal]}"
    tpr = "#{Integer((100.0/@stats[:maxtotal])*@stats[:total])}"
    s.write ">> completed: #{scm} (#{spr}%), total: #{tcm} (#{tpr}%)\n"
    return s.string
  end
end

class Game
  attr_accessor :sets, :listener
  def initialize(sets, neverball_scores, reverse, timer)
    @neverball_scores = neverball_scores
    @sets = {}
    @reverse = reverse
    @timer = false
    @timer_now = Time.now.to_f
    if timer
      @timerfile = timer
      if File.file? timer
        File.open(timer) { |f|
          @timer = Float(f.read.chomp)
        }
      else
        @timer = true
      end
    end
    sets.each { |s|
      @sets[s] = LevelSet.new(s, neverball_scores)
    }
    @listener = Listen.to(@neverball_scores) do |modified, added, removed|
      [modified,added,removed].each { |f|
        f.each { |g|
          puts g+"..."
          n = File.basename(g).split(".")[0]
          if @sets.include?(n)
            puts "\tupdate #{n}"
            @sets[n].update
          end
        }
      }
      update
      print_me
    end
    update
    print_me
    @listener.start
  end
  def update
    if @timer == true
      puts "press enter to start timer..."
      STDIN.readline
      @timer_now = Time.now.to_f
      @timer = @timer_now
      File.open(@timerfile, "w") { |f|
        f.puts(@timer.inspect)
      }
    elsif @timer
      @timer_now = Time.now.to_f
    end
    stats = { completed: 0, maxcompleted: 0, total: 0, maxtotal: 0 }
    @sets.each { |set|
      st = set[1].stats
      stats[:completed] += st[:completed]
      stats[:maxcompleted] += st[:maxcompleted]
      stats[:total] += st[:total]
      stats[:maxtotal] += st[:maxtotal]
    }
    @stats = stats
  end
  def to_pretty_string
    s = StringIO.new
    if @timer
      s.write("\n  [ %s ]\n\n" % (@timer_now-@timer).to_s_timer)
    end
    @sets.each { |set|
      s.puts set[1].to_pretty_string(@reverse) + "\n"
    }
    scm = "#{@stats[:completed]}/#{@stats[:maxcompleted]}"
    spr = "#{Integer((100.0/@stats[:maxcompleted])*@stats[:completed])}"
    tcm = "#{@stats[:total]}/#{@stats[:maxtotal]}"
    tpr = "#{Integer((100.0/@stats[:maxtotal])*@stats[:total])}"
    s.write " ## total >> completed: #{scm} (#{spr}%), total: #{tcm} (#{tpr}%)\n"
    s.string
  end
  def print_me
    clear
    puts to_pretty_string
  end
end
