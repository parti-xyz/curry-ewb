class AgentsController < ApplicationController
  load_and_authorize_resource

  def index
    if params[:position_name]
      @agents = Agent.of_position_names(params[:position_name]).order(:name)
    else
      @agents = Agent.order(:name)
    end
  end

  def show
    @agendas = Agenda.where(id: AgendasIssue.where(issue: Issue.where(id: @agent.opinions.select(:issue_id))).select(:agenda_id).distinct)
    if params[:agenda_id].present?
      @agenda = Agenda.find params[:agenda_id]
      respond_to do |format|
        format.js { render 'agents/show_agenda' }
        format.html
      end
    end
  end
end
