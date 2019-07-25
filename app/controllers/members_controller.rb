class MembersController < ApplicationController
  before_filter :auth_member!, except: [:remaining_limit]
  before_filter :auth_no_initial!, except: [:remaining_limit]

  def edit
    @member = current_user
  end

  def update
    @member = current_user

    if @member.update_attributes(member_params)
      redirect_to forum_path
    else
      render :edit
    end
  end

  def remaining_limit
    limit_account = Figaro.env.limit_account.to_i
    if limit_account != -1
      remain = limit_account - Member.count
    else
      remain = (2**(0.size * 8 -2) -1) # MAX integer
    end

    render text: remain, layout: false
  end

  private
  def member_params
    params.required(:member).permit(:display_name)
  end
end
