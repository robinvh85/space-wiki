module Ajax
  class PolosController < ActionController::Base
    
    def update
      Poloni.update(polo_params)
      render json: {
        status: 'OK'
      }
    end

    private
    def polo_params
      params.require(:polo).permit(:note)
    end
  end
end