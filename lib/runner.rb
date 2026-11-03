# frozen_string_literal: true

# Runs a code submission + its tests in a subprocess. Stdlib only, so
# bin/validate_content can use it without Bundler or Postgres.
require "open3"
require "tmpdir"

module Runner
  TIMEOUT = 10
  MAX_OUTPUT = 20_000
  ROOT = File.expand_path("..", __dir__)
  LANG = {
    "ruby"   => { bin: "ruby",   ext: "rb",  args: ["-W0"] },
    "elixir" => { bin: "elixir", ext: "exs", args: [] }
  }.freeze

  Result = Struct.new(:ok, :output, :status) do
    def passed? = ok
  end

  # asdf picks versions from .tool-versions in cwd; we run in a tmpdir, so pin them explicitly.
  def self.env
    @env ||= begin
      e = { "PATH" => ENV["PATH"], "HOME" => ENV["HOME"], "LANG" => ENV["LANG"] || "en_US.UTF-8" }
      tv = File.join(ROOT, ".tool-versions")
      if File.exist?(tv)
        File.readlines(tv, chomp: true).each do |line|
          tool, version = line.split(" ", 2)
          e["ASDF_#{tool.upcase}_VERSION"] = version if tool && version
        end
      end
      e
    end
  end

  def self.available?(language)
    bin = LANG.fetch(language)[:bin]
    system(env, "which", bin, out: File::NULL, err: File::NULL, unsetenv_others: true)
  end

  def self.run(language, code, tests)
    cfg = LANG.fetch(language) { return Result.new(false, "unsupported language #{language}", nil) }
    unless available?(language)
      return Result.new(false, "`#{cfg[:bin]}` not found on PATH. Install the version pinned in .tool-versions (asdf install).", nil)
    end

    Dir.mktmpdir("quiz") do |dir|
      file = File.join(dir, "run.#{cfg[:ext]}")
      File.write(file, "#{code}\n\n#{tests}\n")
      Open3.popen2e(env, cfg[:bin], *cfg[:args], file, chdir: dir, unsetenv_others: true) do |stdin, out, wait|
        stdin.close
        reader = Thread.new { out.read }
        if wait.join(TIMEOUT)
          st = wait.value
          Result.new(st.success?, reader.value.to_s[0, MAX_OUTPUT], st.exitstatus)
        else
          Process.kill("KILL", wait.pid) rescue nil
          Result.new(false, "Timed out after #{TIMEOUT}s.\n#{reader.value.to_s[0, MAX_OUTPUT]}", nil)
        end
      end
    end
  end
end
