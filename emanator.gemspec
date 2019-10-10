# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'emanator/version'

Gem::Specification.new do |spec|
  spec.name          = 'emanator'
  spec.version       = Emanator::VERSION
  spec.authors       = ['Frank Murphy']
  spec.email         = ['fmurphy@instructure.com']

  spec.summary       = 'incremental updates of materialized views'
  spec.description   = 'incremental updates of materialized views'
  spec.homepage      = 'https://github.com/anirishduck/emanator.rb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sql-parser', '~> 0.0.2'
end
