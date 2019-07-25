module Stratum
  module WalletGroup
	  class << self

			def initialize()
			end

			def list(params = {})
				Stratum.wallet_group('list', params)
			end

			def create(params = {})
				Stratum.wallet_group('create', params)
			end

			def get(params = {})
				Stratum.wallet_group('get', params)
			end
		
	  end
  end
end
