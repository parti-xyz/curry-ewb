class EventsController < ApplicationController
  include OrganizationHelper

  load_and_authorize_resource
  before_action :reset_meta_tags, only: :show
  before_action :fetch_current_organization, only: [:show, :edit]

  def index
    @events = Event.recent
    @current_organization = fetch_organization_of_request(request)
    @events = @events.by_organization(@current_organization) if @current_organization.present?
  end

  def show
    @project = @event.project
    @speeches = @event.speeches.recent.limit(browser.device.mobile? ? 4 : 8) if @event.template == 'speech'
    @hero_speech = @event.speeches.sample

    @comments = params[:tag].present? ? @event.comments.tagged_with(params[:tag]) : @event.comments
    @comments = params[:toxic].present? ? @comments.where(toxic: true) : @comments.where(toxic: false)
    @comments = @comments.order('id DESC')
    @comments = @comments.page(params[:page]).per 50
  end

  def new
  end

  def create
    @event.user = current_user
    if @event.save
      redirect_to @event
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to @event
    else
      render 'edit'
    end
  end

  def destroy
    @event.destroy
    redirect_to evnts_path
  end

  private

  def fetch_current_organization
    @current_organization = @project.organization
  end

  def event_params
    params.require(:event).permit!
  end

  def reset_meta_tags
    prepare_meta_tags({
      title: @event.title,
      description: @event.body.html_safe,
      url: request.original_url,
      image: (view_context.image_url(@event.fallback_social_image_url) if @event.fallback_social_image_url),
    })
  end
end
