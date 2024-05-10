# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
#
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
# port_number = ENV.fetch("RAILS_ENV", "development") == "development" ? "3001" : "3000"
# port ENV.fetch("PORT") { port_number }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

if ENV["RAILS_ENV"] == "production" # This only runs in a VM with local access, so production this is good
  # Fail if in production but the keys don't exist
  certs_path = "/home/parallels/Desktop/Parallels Shared Folders/env_injection_files/ssl_certs"
  unless File.exist?("#{certs_path}/localhost-key.pem") &&
            File.exist?("#{certs_path}/localhost.pem")
    raise "SSL Certs must be in `#{certs_path}`"
  end

  # TODO: Make sure production can be accessed externally
  localhost_key = "#{File.join("#{certs_path}/localhost-key.pem")}"
  localhost_crt = "#{File.join("#{certs_path}/localhost.pem")}"
  # To be able to use rake etc
  ssl_bind "0.0.0.0", 3000, {
    key: localhost_key,
    cert: localhost_crt,
    verify_mode: "none"
  }
else
  bind "tcp://0.0.0.0:3000"
end
