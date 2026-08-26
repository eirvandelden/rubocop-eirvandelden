Gem::Specification.new do |spec|
  spec.name          = "rubocop-eirvandelden"
  spec.version       = "0.1.0"
  spec.authors       = [ "Etienne van Delden" ]
  spec.email         = [ "etienne@conductor.build" ]
  spec.homepage      = "https://github.com/eirvandelden/rubocop-eirvandelden"
  spec.summary       = "Shared RuboCop configuration for personal Ruby projects"
  spec.description   = "The RuboCop rules every personal Ruby project inherits, so a rule " \
                       "changes in one place instead of in every repository."
  spec.license       = "Nonstandard"

  spec.required_ruby_version = ">= 4.0"

  spec.files = Dir["config/**/*.yml", "LICENSE.md", "README.md", "CHANGELOG.md"]

  spec.add_dependency "rubocop"
  spec.add_dependency "rubocop-rails-omakase"
  spec.add_dependency "rubocop-minitest"
  spec.add_dependency "rubocop-obsession"
  spec.add_dependency "rubocop-packaging"
  spec.add_dependency "rubocop-performance"
  spec.add_dependency "rubocop-rails"
  spec.add_dependency "rubocop-rspec"
  spec.add_dependency "rubocop-yard"
end
