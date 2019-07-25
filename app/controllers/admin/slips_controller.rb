module Admin
  class SlipsController < BaseController

    def update
      if Slip.ids.include?(slip_params[:method].to_i)
        Slip.update_system_slip(slip_params[:method])
        flash[:notice] = I18n.t("admin.slips.update_succ")
      end

      redirect_to admin_dashboard_path
    end

    private

    def slip_params
      params.permit(:method)
    end

  end
end

