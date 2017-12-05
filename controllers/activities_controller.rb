class ActivitiesController < ApplicationController
  # GET /activities
  # GET /activities.xml
  # before_filter :check_if_admin, :except => [ :index, :index_of_plan, :show_pictures ]
  
  def index
    # 预设取今年的活动记录
    @year = params[:year] || Date.today.year
    @activities = Activity.all( :conditions => "begin_date >= '#{@year}-01-01'", :order => "begin_date" ) # is_achievement = 't'

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @activities }
    end
  end
  
  def plan_list
    build_list_var    
  end

  def plan_chart
    build_list_var
    @dates = []
    # 决定日期表格资料的起始日与最终日并设定好dates_arr的内容
    @dates = prepare_dates_arr_data( @dates, @activities, "begin_date", "asc" )
  end  

  def build_list_var
    params[:num_month_ago] ||= 0
    params[:sub_title] ||= '本月'
    session[:period_title] = params[:sub_title]
    @sub_title = params[:sub_title] + '的'
    previous_month = Date.today - 1.month
    @act_year = previous_month.year
    @act_month = previous_month.month
    @list_type = "plan" # plan:表示计划表 | rec:表示记录表
    @activities = Activity.all( :conditions => "begin_date >= '#{Date.today}'", :order => "begin_date,begin_time" )
  end

  def show_pictures
    act = Activity.find(params[:id])
    @begin_date = act.begin_date
    @title = act.title
    @folder_name = act.picture_folder_name
    @pictures = Dir.glob(RAILS_ROOT+"/public/images/activities/#{@folder_name}/*.*").map {|f| File.basename(f)}
  end

  # GET /activities/1
  # GET /activities/1.xml
  def show
    @activity = Activity.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @activity }
    end
  end

  # GET /activities/new
  # GET /activities/new.xml
  def new
    @activity = Activity.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @activity }
    end
  end

  # GET /activities/1/edit
  def edit
    @activity = Activity.find(params[:id])
  end

  # POST /activities
  # POST /activities.xml
  def create
    @activity = Activity.new(params[:activity])

    respond_to do |format|
      if @activity.save
        flash[:notice] = 'Activity was successfully created.'
        if @activity.is_achievement
          format.html { redirect_to :action => 'index' }
        else
          format.html { redirect_to :action => 'plan_chart' }
        end
        format.html { redirect_to :action => :plan_chart }
        format.xml  { render :xml => @activity, :status => :created, :location => @activity }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @activity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /activities/1
  # PUT /activities/1.xml
  def update
    @activity = Activity.find(params[:id])

    respond_to do |format|
      if @activity.update_attributes(params[:activity])
        flash[:notice] = 'Activity was successfully updated.'
        if @activity.is_achievement
          format.html { redirect_to :action => 'index' }
        else
          format.html { redirect_to :action => 'plan_chart' }
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @activity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /activities/1
  # DELETE /activities/1.xml
  def destroy
    @activity = Activity.find(params[:id])
    @activity.destroy

    respond_to do |format|
      format.html { redirect_to :action => :plan_chart }
      format.xml  { head :ok }
    end
  end
end
