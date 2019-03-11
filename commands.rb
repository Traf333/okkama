require "./okkama"

reports = Dir["/Users/jorik/projects/okkama/reports/*"]
transaction = Dir["/Users/jorik/projects/okkama/transactions/*"].first

FileUtils.mkdir_p("build/#{Date.today}")

reports.each do |report|
  r = Okkama.new(transaction, report)
  r.build
end
