namespace :stores do
  desc "Copy rep's store feed now (FILE=path.json loads a saved feed instead, for dev)"
  task sync: :environment do
    if ENV["FILE"].present?
      body = JSON.parse(File.read(ENV["FILE"]))
      file_client = Struct.new(:rows) do
        def stores(etag: nil) = Rep::Client::Feed.new(rows: rows, etag: nil, as_of: Time.current, token_expires_at: nil, not_modified: false)
      end.new(body.fetch("data"))
      run = StoreFeed.new(file_client).sync!
    else
      run = StoreFeed.sync!
    end
    puts "#{run.status}: #{run.stores_count.inspect} stores#{" (#{run.error})" if run.error}"
  end

  desc "Last sync runs and token expiry"
  task status: :environment do
    puts "#{Store.count} stores"
    SyncRun.recent.limit(5).each do |r|
      puts [ r.started_at.iso8601, r.status, r.stores_count, r.token_expires_at&.to_date, r.error ].compact.join("  ")
    end
  end
end
