# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :docs do
  desc 'Generate YARD documentation'
  task :generate do
    sh 'yard doc'
  end

  desc 'Start YARD documentation server'
  task :server do
    sh 'yard server --reload'
  end
end

desc 'Start an interactive console'
task :console do
  require 'pry'
  require_relative 'lib/eleven_rb'
  Pry.start
end
