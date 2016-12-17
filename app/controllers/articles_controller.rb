class ArticlesController < ApplicationController
  load_and_authorize_resource
  HASHTAG_REGEX = /(?:\s|^)(#(?!(?:\d+|[ㄱ-ㅎ가-힣a-z0-9_]+?_|_[ㄱ-ㅎ가-힣a-z0-9_]+?)(?:\s|$))([ㄱ-ㅎ가-힣a-z0-9\-_]+))/i

  def index
    sort = params[:sort] || 'hot'
    @articles = Article.send(sort).recent.page params[:page]
  end

  def new
    @article = Article.new
  end

  def create
    @article.user = current_user
    hastag
    if @article.save
      CrawlingJob.perform_async(@article.id)
      redirect_to articles_path(sort: :recent)
    else
      errors_to_flash(@article)
      render :new
    end
  end

  def edit
  end

  def update
    @article.assign_attributes(article_params)
    hastag
    if @article.save
      CrawlingJob.perform_async(@article.id)
      redirect_to article_path(@article)
    else
      errors_to_flash(@article)
      render :new
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_path
  end

  private

  def article_params
    params.require(:article).permit(:url, :body)
  end

  def hastag
    return if @article.body.blank?
    strip_body = Nokogiri::HTML(@article.body).xpath('//text()').map(&:text).join(' ').gsub("&nbsp;", " ")
    @article.tag_list = strip_body.scan(HASHTAG_REGEX).map { |match| match[1] }.join(', ')
  end
end