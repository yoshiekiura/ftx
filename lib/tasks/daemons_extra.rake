namespace :daemons_extra do

  task :start do |task, args|
    puts "Starting all daemons"
    results = []
    Dir[File.dirname(__FILE__) + "/../daemons/*_ctl"].each {|f| results << `ruby #{f} start`}
    results.delete_if { |result| result.nil? || result.empty? }
    puts results.join unless results.empty?
  end

  task :start_one, [:element] do |task, args|
    puts "Starting daemon #{args[:element].inspect}"

    results = []
    f = File.dirname(__FILE__) + "/../daemons/#{args[:element]}_ctl"
    results << `ruby #{f} start`
    results.delete_if { |result| result.nil? || result.empty? }
    puts results.join unless results.empty?
  end

  task stop: :environment do
    puts "Stopping all daemons"
    results = []
    Dir[File.dirname(__FILE__) + "/../daemons/*_ctl"].each {|f|
      puts "ruby #{f} stop"
      results << `ruby #{f} stop`}
    results.delete_if { |result| result.nil? || result.empty? }
    puts results.join unless results.empty?
  end

  task :stop_one, [:element] do |task, args|
    puts "Stopping daemon #{args[:element].inspect}"

    results = []
    f = File.dirname(__FILE__) + "/../daemons/#{args[:element]}_ctl"
    results << `ruby #{f} stop`
    results.delete_if { |result| result.nil? || result.empty? }
    puts results.join unless results.empty?
  end

  # TODO: implement https://gist.github.com/mtrense/f325e04b291388bbb69f

end