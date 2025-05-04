# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ivar"
require "stringio"

require "minitest/autorun"

# Helper method to capture stderr during a block
def capture_stderr
  original_stderr = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  $stderr = original_stderr
end
