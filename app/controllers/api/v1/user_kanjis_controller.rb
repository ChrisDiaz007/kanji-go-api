class Api::V1::UserKanjisController < ApplicationController
  def show
    @user_kanji = UserKanji.find(params[:id])
    authorize @user_kanji
    render json: @user_kanji
  end

  def update?
    @user_kanji = UserKanji.fund(find(params[:id]))
    authorize @user_kanji
    if @user_kanji.update(user_kanji_params)
      render json: @user_kanji
    else
      render json: { errors: @user_kanji.errors }, status: :unprocessable_entity
    end
  end

end
