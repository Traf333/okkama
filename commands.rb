require "./okkama"

reports = Dir["/Users/jorik/projects/okkama/reports/*"]
transaction = Dir["/Users/jorik/projects/okkama/transactions/*"].first

FileUtils.mkdir_p("build/#{Date.today}")

r = Okkama.new(transaction, reports)
r.build
