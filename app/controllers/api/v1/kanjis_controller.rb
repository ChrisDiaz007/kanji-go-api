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
end
