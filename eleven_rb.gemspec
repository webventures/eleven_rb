# frozen_string_literal: true

require_relative "lib/eleven_rb/version"

Gem::Specification.new do |spec|
  spec.name = "eleven_rb"
  spec.version = ElevenRb::VERSION
  spec.authors = ["Web Ventures Ltd"]
  spec.email = ["gems@dev.webven.nz"]

  spec.summary = "Ruby client for the ElevenLabs Text-to-Speech API"
  spec.description = <<~DESC
    A well-structured Ruby gem for ElevenLabs TTS with voice library management,
    streaming support, voice slot optimization, and comprehensive callbacks for
    logging, error tracking, and cost monitoring.
  DESC
  spec.homepage = "https://github.com/webventures/eleven_rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "README.md", "CHANGELOG.md", "LICENSE"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "base64", ">= 0.1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "vcr", "~> 6.2"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "yard", "~> 0.9"
end
