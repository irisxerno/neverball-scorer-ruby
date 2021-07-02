Gem::Specification.new do |s|
  s.name        = 'neverball-scorer-ruby'
  s.version     = '0.1.1'
  s.licenses    = ['MIT']
  s.summary     = "A scoreboard for neverball."
  s.description = "TUI scoreboard for achievements in neverball"
  s.authors     = ["Anttu Kaihlavirta"]
  s.email       = 'antsuke42@gmail.com'
  s.homepage    = 'https://github.com/antsuke42/neverball-scorer-ruby'
  s.files       = ["lib/scores.rb", "lib/defaults.txt"]
  s.add_dependency 'listen', '~> 3.1'
  s.executables << 'neverball-scorer-ruby'
end
