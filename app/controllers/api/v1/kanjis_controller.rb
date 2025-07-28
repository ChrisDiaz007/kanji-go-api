class Api::V1::KanjisController < ApplicationController
  def index
    @kanjis = Kanji.all
    if params[:character].present?
      @kanjis = Kanji.where('character ILIKE ?', "%#{params[:character]}%")
    else
      @kanjis = Kanji.all
    end
    render json: @kanjis
  end

  def show
    @kanji = Kanji.find_by(character: params[:id])
    if @kanji
      render json: @kanji
    else
      render json: { error: "Kanji not found" }, status: :not_found
    end
  end

end
