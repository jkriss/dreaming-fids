require 'fileutils'

class SinatraServer
  def pid_dir
    "./"
  end
  def pid_path
    pid_dir + "sinatra.pid"
  end
  def run
    exec "ruby fishery.rb -e production"
  end
  def start
    if File.exist?(pid_path)
      existing_pid = IO.read(pid_path).to_i
      begin
        Process.kill(0, existing_pid)
        raise(Exception, "Server is already running with PID #{existing_pid}")
      rescue Errno::ESRCH
        STDERR.puts("Removing stale PID file at #{pid_path}")
        FileUtils.rm(pid_path)
      end
    end
    fork do
      pid = fork do
        Process.setsid
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen(STDOUT)
        run
      end
      FileUtils.mkdir_p(pid_dir)
      File.open(pid_path, 'w') do |file|
        file << pid
      end
    end
  end
  def stop
    if File.exist?(pid_path)
      pid = IO.read(pid_path).to_i
      begin
        Process.kill('TERM', pid)
      rescue Errno::ESRCH
        raise Exception, "Process with PID #{pid} is no longer running"
      ensure
        FileUtils.rm(pid_path)
      end
    else
      raise Exception, "No PID file at #{pid_path}"
    end
  end
end