module Benchmark
  class SweatFactory

    @@seq = 0

    class <<self
      def make_member
        @@seq += 1
        member = Member.create!(
          email: "userblabla#{@@seq}@example.com",
        )
      end

      def make_order(klass, attrs={})
        klass.new({
          bid: :brl,
          ask: :btc,
          ord_type:      'limit',
          state: Order::WAIT,
          currency: :btcbrl,
          origin_volume: attrs[:volume],
          source: 'Web',
          locked: 0,
          origin_locked: 0
        }.merge(attrs))
      end
    end

  end
end
