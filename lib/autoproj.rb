require "enumerator"
require 'autobuild'
require 'autoproj/base'
require 'autoproj/version'
require 'autoproj/manifest'
require 'autoproj/osdeps'
require 'autoproj/system'
require 'autoproj/options'
require 'autoproj/cmdline'
require 'autoproj/query'
require 'logger'
require 'utilrb/logger'

module Autoproj
    class << self
        attr_reader :logger
    end
    @logger = Logger.new(STDOUT)
    logger.level = Logger::WARN
    logger.formatter = lambda { |severity, time, progname, msg| "#{severity}: #{msg}\n" }
    extend Logger::Forward
end

