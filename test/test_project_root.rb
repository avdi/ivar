# frozen_string_literal: true

require_relative "test_helper"
require "fileutils"
require "tmpdir"

class TestProjectRoot < Minitest::Test
  def setup
    # Create a temporary directory structure for testing
    @temp_dir = Dir.mktmpdir("ivar_test")

    # Create a nested directory structure
    @project_dir = File.join(@temp_dir, "project")
    @lib_dir = File.join(@project_dir, "lib")
    @deep_dir = File.join(@lib_dir, "deep", "nested", "dir")

    FileUtils.mkdir_p(@deep_dir)

    # Create a Gemfile in the project directory
    File.write(File.join(@project_dir, "Gemfile"), "source 'https://rubygems.org'")

    # Create a test file in the deep directory
    @test_file = File.join(@deep_dir, "test_file.rb")
    File.write(@test_file, "# Test file")
  end

  def teardown
    # Clean up the temporary directory
    FileUtils.remove_entry(@temp_dir)
  end

  def test_project_root_finds_gemfile
    # Test that project_root correctly finds the directory with Gemfile
    assert_equal @project_dir, Ivar.project_root(@test_file)
  end

  def test_project_root_caching
    # Test that project_root caches results
    first_result = Ivar.project_root(@test_file)

    # Delete the Gemfile to ensure it's using the cached result
    FileUtils.rm(File.join(@project_dir, "Gemfile"))

    second_result = Ivar.project_root(@test_file)
    assert_equal first_result, second_result
  end

  def test_project_root_with_git
    # Test that project_root finds .git directory
    git_dir = File.join(@project_dir, ".git")
    FileUtils.mkdir_p(git_dir)

    assert_equal @project_dir, Ivar.project_root(@test_file)
  end

  def test_project_root_fallback
    # Test fallback when no indicators are found
    no_indicators_dir = File.join(@temp_dir, "no_indicators")
    FileUtils.mkdir_p(no_indicators_dir)
    test_file = File.join(no_indicators_dir, "test.rb")
    File.write(test_file, "# Test file")

    # Should return the directory of the file
    assert_equal no_indicators_dir, Ivar.project_root(test_file)
  end

  def test_project_root_with_caller
    # Create a file that calls project_root
    caller_file = File.join(@deep_dir, "caller.rb")
    File.write(caller_file, <<~RUBY)
      # frozen_string_literal: true

      def get_project_root_from_caller
        Ivar.project_root
      end
    RUBY

    # Load the file
    require caller_file

    # Test that project_root correctly uses the caller's location
    assert_equal @project_dir, get_project_root_from_caller
  end
end
