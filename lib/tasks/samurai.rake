namespace :samurai do

  task test: :environment do
    Samurai.logger.level = Logger::DEBUG

    # payload = '{ "email": "support@cointrade.cx",
    #               "coin": "bitcoin",
    #               "fiat": "brl",
    #               "fake": true,
    #             "source": "cointrade",
    #            "address": "fake" }'
    # puts payload
    # response = Samurai::Order.create(payload)
    # puts "CREATED TEF data = #{response.data}"

    # payload = '{ "email": "ildo.grings@cointrade.cx",
    #           "coin": "bitcoin",
    #           "fiat": "brl",
    #         "amount": "667",
    #           "fake": true,
    #         "source": "cointrade",
    #       "document": "10219888035",
    #        "address": "fake" }'
    # puts payload
    # response = Samurai::Order.create(payload)
    # puts "CREATED TED data = #{response.data}"

    response = Samurai::Order.status('1e1da7fc-8647-4cfa-ade4-47fedcd2e5f8')
    puts "data = #{response.data}"
    puts "status = #{response.status}"

    response = Samurai::Order.status('9b2def48-e3c3-45ff-a1b4-eefb6c5ed09d')
    puts "data = #{response.data}"
    puts "status = #{response.status}"

    # response = Samurai::Order.status('7f0f5d58-869e-4cc3-9a80-f7916cc441cc')
    # puts "data = #{response.data}"
    # puts "status = #{response.status}"

  end
end