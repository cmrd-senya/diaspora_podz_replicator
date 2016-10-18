# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "diaspora_podz_replicator"
  s.version     = "0.1.0"
  s.authors     = ["cmrd Senya"]
  s.email       = ["senya@riseup.net"]
  s.homepage    = "https://github.com/cmrd-senya/diaspora_podz_replicator"
  s.summary     = "Tools for fast deploy of diaspora pods primarily for test purposes"
  s.description = "Tools for fast deploy of diaspora pods primarily for test purposes"
  s.license     = "AGPL-3.0"

  s.files       =
    [
      *`git ls-files`.split("\n"),
      *`cd #{File.dirname(__FILE__)}/vendor/replica && git ls-files | sed "s|^|vendor/replica/$path/|"`.split("\n"),
      *`cd #{File.dirname(__FILE__)}/vendor/replica && git submodule --quiet foreach 'git ls-files | sed "s|^|vendor/replica/$path/|"'`.split("\n")
    ]
  s.require_paths = ["lib"]
  s.executables << "preplica"

  s.add_runtime_dependency "capistrano"
  s.add_runtime_dependency "capistrano-rvm"
  s.add_runtime_dependency "capistrano-rails", "~> 1.1"
  s.add_runtime_dependency "capistrano-rails-collection", "~> 0.1"
  s.add_runtime_dependency "capistrano-db-tasks"
  s.add_runtime_dependency "trollop"
end
