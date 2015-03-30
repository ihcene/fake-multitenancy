require "fake/multitenancy/version"
require "active_record"
require "active_support"
require "active_support/core_ext"

module Fake
  module Multitenancy
  end
end

require 'fake/multitenancy/abstract_adapter'
require 'fake/multitenancy/active_record/base/multitenancy'
require 'fake/multitenancy/active_record/schema_dumper'
require 'fake/multitenancy/active_record/base'