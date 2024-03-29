# frozen_string_literal: true

class AnimeController < ApplicationController
  before_action :authenticate_user!, only: %i[progress add_progress get_status change_status]

  # GET /anime
  # GET /anime.json
  def index
    list = if !genres.blank?
             Genre.find_by(id: genres).anime
           else
             Anime
           end
    list = list.with_attached_poster.includes(:genres)
    list = list.where(hide: false)
    list = list.search_by_title(search) unless search.empty?
    list = list.where(year: year) unless year.empty?
    list = list.order(sort_by_order) if sort_by_order

    @animes = list.page(page).per(limit)
    @title = 'Поиск'
    @query = {
      q: search,
      year: year,
      sort_by: sort_by,
      genres: genres
    }
    respond_to do |format|
      format.html { render :index, layout: 'sidebar' }
      format.json { render json: @animes }
    end
  end

  # GET /anime/1
  # GET /anime/1.json
  def show
    @anime = Anime.includes(:anime_translators, :genres)
                 .with_attached_poster
                 .with_attached_background
                 .find(params[:id])
    @title = @anime.title
    @desc = @anime.description

    respond_to do |format|
      format.html { render :show, layout: 'sidebar' }
      format.json { render json: @anime }
    end
  end

  # GET /api/v1/anime/:id/progress
  def progress
    @anime = Anime.find(params[:id])

    respond_to do |format|
      format.json { render json: @anime.last_watch(current_user.id) }
    end
  end

  # POST /api/v1/anime/:id/progress
  def add_progress
    params.permit(:translator_id, :episode_id)

    anime = Anime.find(params[:id])
    tr = anime.translators.find(params[:translator_id])

    progress = AnimeProgress.create!(anime: anime,
                                     anime_translator: tr,
                                     episode: tr.episodes.find(params[:episode_id]),
                                     user: current_user)

    respond_to do |format|
      format.json { render json: progress }
    end
  end

  # GET /api/v1/anime/:id/status
  def get_status
    respond_to do |format|
      format.json do
        render json: UserAnimeStatus
          .where(user: current_user.id, anime: params[:id]).first!
      end
    end
  end

  # POST /api/v1/anime/:id/status
  def change_status
    params.permit(:status)

    as = UserAnimeStatus
         .where(user: current_user.id, anime: params[:id])
         .first_or_create!(status: params[:status])
         .update!(status: params[:status])

    respond_to do |format|
      format.json do
        render json: as
      end
    end
  end

  private

  def search
    params[:q] || ''
  end

  def limit
    params[:limit] || 25
  end

  def page
    params[:page] || 1
  end

  def genres
    params[:genres]
  end

  def year
    params[:year] || ''
  end

  def sort_by
    params[:sort_by]
  end

  def sort_by_order
    case sort_by
    when 'title_desc'
      'title DESC'
    when 'title_asc'
      'title ASC'
    when 'rating_desc'
      'rating DESC'
    when 'rating_asc'
      'rating ASC'
    when 'year_desc'
      'year DESC'
    when 'year_asc'
      'year ASC'
    when 'created_at_desc'
      'created_at DESC'
    when 'created_at_asc'
      'created_at ASC'
    when 'updated_at_desc'
      'updated_at DESC'
    when 'updated_at_asc'
      'updated_at ASC'
    else
      # default sort
      'rating DESC'
    end
  end
end
