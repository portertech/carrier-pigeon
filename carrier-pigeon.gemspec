Gem::Specification.new do |s|
  s.name        = "carrier-pigeon"
  s.version     = "0.5.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Sean Porter"]
  s.email       = ["portertech@gmail.com"]
  s.homepage    = "https://github.com/portertech/carrier-pigeon"
  s.summary     = %q{The simplest library to say something on IRC}
  s.description = %q{The simplest library to say something on IRC}
  s.has_rdoc    = false
  s.license     = "MIT"

  s.rubyforge_project = "carrier-pigeon"

  s.add_dependency("addressable")

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
end
