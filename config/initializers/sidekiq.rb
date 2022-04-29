Sidekiq.configure_server do |config| 
  config.death_handlers << -> (job, exception) do
    worker = job["wrapped"].safe_constantize
    worker&.sidekiq_retries_exhausted_block&.call(job, exception)
  end
end
