module Private
  class AssetsController < BaseController
    skip_before_action :auth_member!, only: [:index]

    def index
      @brl_assets  = Currency.assets('brl')
      @brl_proof   = Proof.current :brl

      @btc_proof   = Proof.current :btc
      @bch_proof   = Proof.current :bch
      @btg_proof   = Proof.current :btg
      @dash_proof   = Proof.current :dash
      @eth_proof   = Proof.current :eth
      @dgb_proof   = Proof.current :dgb
      @zec_proof   = Proof.current :zec
      @xrp_proof   = Proof.current :xrp
      @smart_proof   = Proof.current :smart
	    @zcr_proof   = Proof.current :zcr
	    @tusd_proof   = Proof.current :tusd
      @xem_proof   = Proof.current :xem
      @rbtc_proof   = Proof.current :rbtc
      @rif_proof   = Proof.current :rif
      @xar_proof   = Proof.current :xar

      if current_user
        @btc_account = current_user.accounts.with_currency(:btc).first
        @brl_account = current_user.accounts.with_currency(:brl).first

        @bch_account = current_user.accounts.with_currency(:bch).first
        @btg_account = current_user.accounts.with_currency(:btg).first
        @dash_account = current_user.accounts.with_currency(:dash).first
        @eth_account = current_user.accounts.with_currency(:eth).first
        @dgb_account = current_user.accounts.with_currency(:dgb).first
        @zec_account = current_user.accounts.with_currency(:zec).first
        @xrp_account = current_user.accounts.with_currency(:xrp).first
        @smart_account = current_user.accounts.with_currency(:smart).first
		    @zcr_account = current_user.accounts.with_currency(:zcr).first
		    @tusd_account = current_user.accounts.with_currency(:tusd).first

        @xem_account = current_user.accounts.with_currency(:xem).first
        @rbtc_account = current_user.accounts.with_currency(:rbtc).first
        @rif_account = current_user.accounts.with_currency(:rif).first
        @xar_account = current_user.accounts.with_currency(:xar).first
      end
    end

    def partial_tree
      account    = current_user.accounts.with_currency(params[:id]).first
      @timestamp = Proof.with_currency(params[:id]).last.timestamp
      @json      = account.partial_tree.to_json.html_safe
      respond_to do |format|
        format.js
      end
    end

  end
end
