class TasksController < ApplicationController
  before_filter :login_required
  before_filter :find_task, :only => [:show, :edit, :update, :destroy, :complete, :uncomplete]

  def index
    @tasks = current_user.tasks
    @dated_tasks = current_user.tasks.dated
    @later_tasks = current_user.tasks.later
    @asap_tasks  = current_user.tasks.asap
    @categories  = current_user.categories_values
    
    unless cookies[:been_here]
      @first_time = true
      cookies[:been_here] = { :value => 'true', :expires => 1.year.since }
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @tasks.to_xml }
    end
  end
  
  def completed
    @tasks = current_user.tasks.completed
    
    respond_to do |format|
      format.html # completed.rhtml
      format.xml  { render :xml => @tasks.to_xml }
    end
  end

  def show
    respond_to do |format|
      format.xml  { render :xml => @task.to_xml }
      format.js   { render :partial => 'task' }
    end
  end

  def new
    @task = current_user.tasks.build
  end

  def edit
    current_user.categories.reload
    @categories = current_user.categories.collect{ |c| [c.name, c.id] }.sort_by { |pair| pair.first.downcase }
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @task = current_user.tasks.build(params[:new_task])
    
    if @task.due_on.nil?
      @task.kind = params[:later] ? 'later' : 'asap'
    end

    respond_to do |format|
      if @task.save
        flash[:notice] = 'Task was successfully created.'
        format.html { redirect_to tasks_url }
        format.xml  { head :created, :location => task_url(@task) }
        format.js
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @task.errors.to_xml }
        format.js   { head :error }
      end
    end
  end

  def update
    @old_due_on = @task.due_on

    respond_to do |format|
      if @task.update_attributes(params[:task])
        flash[:notice] = 'Task was successfully updated.'
        format.html { redirect_to tasks_url }
        format.xml  { head :ok }
        format.js
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @task.errors.to_xml }
        format.js   { head :error }
      end
    end
  end

  def destroy
    @task.destroy

    respond_to do |format|
      format.html { redirect_to tasks_url }
      format.xml  { head :ok }
      format.js
    end
  end
  
  def complete
    @task.complete
    @task.save
    
    respond_to do |format|
      format.js
      format.xml  { head :ok }
    end
  end

  def uncomplete
    @task.uncomplete
    @task.save

    respond_to do |format|
      format.js
      format.xml { head :ok }
    end
  end
  
  def sort
    if param_key = params.keys.detect { |k| k.to_s =~ /^tasks_/ }
      section = param_key.to_s.match(/^tasks_(.*)/)[1]
      date, kind = parse_section(section)
      positions = params[param_key]
      
      positions.each_with_index do |task_id, position|
        task = current_user.tasks.find(task_id)
        task.position = position + 1
        task.due_on = date
        task.kind = kind
        task.save
      end if positions
    end
    
    head :ok
  end
  
  private
    def find_task
      @task = current_user.tasks.find(params[:id])
    end

    def parse_section(section)
      kind = Task::KINDS.include?(section.to_sym) ? section : nil
      unless kind
        date = section.to_i == 0 ? nil : Time.at(section.to_i).to_date
      end
      [date, kind]
    end
end
