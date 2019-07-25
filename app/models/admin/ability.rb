module Admin
  class Ability
    include CanCan::Ability

    def initialize(user)

      return unless user.admin? or user.supporter?

      can :read, Order
      can :read, Trade
      can :read, Proof

      can :read, Proof
      can :read, Document
      can :read, Member
      can :read, Ticket
      can :read, IdDocument
      can :read, TwoFactor

      can :menu, Deposit
      can :read, ::Deposits::Bank
      can :read, ::Deposits::Satoshi
      can :read, ::Deposits::Btc
      can :read, ::Deposits::Bch
      can :read, ::Deposits::Dash
      can :read, ::Deposits::Dgb
      can :read, ::Deposits::Eth
      can :read, ::Deposits::Zec
      can :read, ::Deposits::Xrp
      can :read, ::Deposits::Smart
      can :read, ::Deposits::Btg
      can :read, ::Deposits::Iota
      can :read, ::Deposits::Ltc
	    can :read, ::Deposits::Zcr
	    can :read, ::Deposits::Tusd
      can :read, ::Deposits::Xem
      can :read, ::Deposits::Rbtc
      can :read, ::Deposits::Rif
      can :read, ::Deposits::Xar

      can :menu, Withdraw
      can :read, ::Withdraws::Bank
      can :read, ::Withdraws::Satoshi
      can :read, ::Withdraws::Btc
      can :read, ::Withdraws::Bch
      can :read, ::Withdraws::Dash
      can :read, ::Withdraws::Dgb
      can :read, ::Withdraws::Eth
      can :read, ::Withdraws::Zec
      can :read, ::Withdraws::Xrp
      can :read, ::Withdraws::Smart
      can :read, ::Withdraws::Btg
      can :read, ::Withdraws::Iota
      can :read, ::Withdraws::Ltc
	    can :read, ::Withdraws::Zcr
	    can :read, ::Withdraws::Tusd
      can :read, ::Deposits::Xem
      can :read, ::Deposits::Rbtc
      can :read, ::Deposits::Rif
      can :read, ::Deposits::Xar
		
      return unless user.admin?
      can :update, Proof
      can :manage, Document
      can :manage, Member
      can :manage, Ticket
      can :manage, IdDocument
      can :manage, TwoFactor

      can :manage, ::Deposits::Bank
      can :manage, ::Deposit
      can :manage, ::Deposits::Satoshi
      can :manage, ::Deposits::Btc
      can :manage, ::Deposits::Bch
      can :manage, ::Deposits::Dash
      can :manage, ::Deposits::Dgb
      can :manage, ::Deposits::Eth
      can :manage, ::Deposits::Zec
      can :manage, ::Deposits::Xrp
      can :manage, ::Deposits::Smart
      can :manage, ::Deposits::Btg
      can :manage, ::Deposits::Iota
      can :manage, ::Deposits::Ltc
	    can :manage, ::Deposits::Zcr
      can :manage, ::Deposits::Tusd
      can :manage, ::Deposits::Xem
      can :manage, ::Deposits::Rbtc
      can :manage, ::Deposits::Rif
      can :manage, ::Deposits::Xar
		
      can :manage, ::Withdraws::Bank
      can :manage, ::Withdraws::Satoshi
      can :manage, ::Withdraws::Btc
      can :manage, ::Withdraws::Bch
      can :manage, ::Withdraws::Dash
      can :manage, ::Withdraws::Dgb
      can :manage, ::Withdraws::Eth
      can :manage, ::Withdraws::Zec
      can :manage, ::Withdraws::Xrp
      can :manage, ::Withdraws::Smart
      can :manage, ::Withdraws::Btg
      can :manage, ::Withdraws::Iota
      can :manage, ::Withdraws::Ltc
	    can :manage, ::Withdraws::Zcr
	    can :manage, ::Withdraws::Tusd
      can :manage, ::Withdraws::Xem
      can :manage, ::Withdraws::Rbtc
      can :manage, ::Withdraws::Rif
      can :manage, ::Withdraws::Xar
    end
  end
end
