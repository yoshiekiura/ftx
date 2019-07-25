module Private
  class MarketsController < BaseController
    def show
      redirect_to market_v2_path
    end
  end
end
