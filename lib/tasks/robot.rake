namespace :robot do
  task play: :environment do
  
  
    puts "robot start"
	
	member_a = Member.find_by_id(2)
	member_b = Member.find_by_id(3)
	
	puts "member_a = #{member_a.inspect}"
	puts "member_b = #{member_b.inspect}"
	
	worker = Worker::Robot.new(member_a,member_b)
    worker.run
  
  end 

 
end
