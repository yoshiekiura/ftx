module Worker
  class Robot

    def initialize( member_a, member_b )
      @member_a = member_a
      @member_b = member_b
    end

    def run
      Rails.logger.info "#{self.to_s} collected."
      puts "Robot running"

      require 'securerandom'

      SecureRandom.random_number(100).times do |id|
        puts "id = #{id.inspect}"
      end

    end

    private

  end
end
