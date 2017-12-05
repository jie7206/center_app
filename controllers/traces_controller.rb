class TracesController < ApplicationController
  # GET /traces
  # GET /traces.xml
  # before_filter :check_if_your_traces, :only => [ :edit, :update, :destroy ]
  after_filter :create_or_update_history, :only => [ :update ]

  #確保課程紀錄有最新的資料
  def create_or_update_history
    if @trace.last_class_title.size > 1
      history = History.find(:first, :conditions => [ "member_id = ? and class_date = ? and class_title = ?", @trace.member_id, @trace.last_class_date, @trace.last_class_title ] )
      if !history
        History.create( 
          :member_id => @trace.member_id,
          :area_id => @trace.aid,
          :name => @trace.member.name, 
          :class_date => @trace.last_class_date, 
          :class_teacher => @trace.last_class_teacher, 
          :class_title => @trace.last_class_title, 
          :class_feel => @trace.class_feel, 
          :class_type => @trace.class_type,
          :is_public_class => @trace.is_public_class )
        # 依照会员在本月参加活动的次数，自动更新会员的所属类别
        update_all_members_classification_by_histories_count_month
        # 更新会员的所属类别后，自动
        update_or_create_member_report
        flash[:notice] = @trace.last_class_title + "的活動紀錄新增成功! 并已新增或更新每月报表"
      end
    end
  end  
  
  def index
    session[:last_url] = self.request.url
    @traces = Trace.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @traces }
    end
  end

  # GET /traces/1
  # GET /traces/1.xml
  def show
    @trace = Trace.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @trace }
    end
  end

  # GET /traces/new
  # GET /traces/new.xml
  def new
    @trace = Trace.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trace }
    end
  end

  # GET /traces/1/edit
  def edit
    @trace = Trace.find(params[:id])
    @steps = Step.all( :order => :order_num )
  end

  # POST /traces
  # POST /traces.xml
  def create
    @trace = Trace.new(params[:trace])

    respond_to do |format|
      if @trace.save
        flash[:notice] = 'Trace was successfully created.'
        format.html { redirect_to :controller => 'members', :action => 'index_simple' }
        format.xml  { render :xml => @trace, :status => :created, :location => @trace }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @trace.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /traces/1
  # PUT /traces/1.xml
  def update
    @trace = Trace.find(params[:id])
    params[:trace][:step_ids] = ""
    params[:trace][:step_ids] = params[:step_list].join(",") if params[:step_list]
    
    #將課程紀錄存入session，以便快速新增課程紀錄
    set_auto_history_session( params[:trace][:last_class_date], params[:trace][:last_class_teacher], params[:trace][:last_class_title], params[:trace][:class_type], params[:trace][:aid], params[:trace][:is_public_class] )
    #如果有输入生活类别，则自动新增一笔记录到生活管理表
    if !params[:param_change][:param_id].empty?
      create_new_param_change params 
    end
    respond_to do |format|
      if @trace.update_attributes(params[:trace])
        flash[:notice] = "追蹤紀錄更新成功! ( #{session[:class_date]} : #{session[:class_teacher]} : #{class_type_arr.rassoc(params[:trace][:class_type])[0]} : #{session[:class_title]} )"
        # format.html { redirect_to :controller => 'histories', :action => 'index_by_month_peroid' }
        format.html { redirect_to_index }
        # format.html { redirect_to :action => "edit" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @trace.errors, :status => :unprocessable_entity }
      end
    end
    
  end

  # DELETE /traces/1
  # DELETE /traces/1.xml
  def destroy
    @trace = Trace.find(params[:id])
    @trace.destroy

    respond_to do |format|
      format.html { redirect_to(traces_url) }
      format.xml  { head :ok }
    end
  end
  
  def appointment
  	session[:last_url] = self.request.url
    start_months = 6   #從幾個月前開始列表
    list_month = 8     #要列出幾個月
    @names = []
    @dates = []
    start = get_start_date( Date.today, -7*4*start_months, 1 )
    start.upto(start+(28*list_month - 1)) { |d| @dates << d.to_s(:db) }
  end

  #自動變更為建立家庭
  def auto_change_to_family  
      mids = params[:mids].to_a
      count = 0
      mids.each do |mid|
        @trace = Trace.find(Member.find(mid).trace.id)
        @trace.update_attribute( :status_num , 8 )  #...['建立家庭',8]
        count = count + 1
      end
      flash[:notice] = "#{count}笔紀錄更新成功！"
      redirect_to_index
  end

  # 更新課程預約
  def update_trace_next_values
    exe_update_table_fields_values( Trace, params[:trace][:id], params[:trace] )
    # 建立一笔活动记录以便在活动管理系统中显示
    insert_activity_if_not_exist( params[:trace] )
    redirect_to :controller => :activities, :action => :plan_chart    
  end

  # 建立一笔活动记录以便在活动管理系统中显示
  def insert_activity_if_not_exist( data )
    Activity.create(
                    :title => data[:next_class_title],
                    :content => data[:next_class_content],
                    :begin_date => data[:next_class_date],
                    :begin_time => data[:next_class_time],
                    :end_date => data[:next_class_date],
                    :place => data[:place],
                    :manager => data[:next_class_teacher],
                    :teachers => data[:next_class_teacher],
                    :students => Trace.find(data[:id]).member.name,
                    :expect_people_count => 1 )
  end

end
