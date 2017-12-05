class ParamChangesController < ApplicationController
  # GET /param_changes
  # GET /param_changes.xml
  def index
    if params[:life_keywords_for_search]
      @param_changes = ParamChange.all( :conditions => "title like '%" + params[:life_keywords_for_search] + "%'", :order => 'rec_date desc' )
    else
      @param_changes = ParamChange.all( :order => 'created_at')
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @param_changes }
    end
  end

  # GET /param_changes/1
  # GET /param_changes/1.xml
  def show
    @param_change = ParamChange.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @param_change }
    end
  end

  # GET /param_changes/new
  # GET /param_changes/new.xml
  def new
    @param_change = ParamChange.new

    if params[:param_id]
      @param_changes = ParamChange.all( :order => "rec_date desc, id desc", :conditions => ["param_id = ?", params[:param_id]] )
      @param_change.title = params[:param_title]
      @param_change.change_value = params[:change_value]

      # 如果来自于目标设定的标题，则自动加上开始与结束的时间
      time_interval_str = "[xx:xx - #{Time.now.strftime("%H:%M")}] "
      if params[:life_goal_id]
        @param_change.title = time_interval_str + @param_change.title
      elsif @param_changes and @param_changes.first and @param_changes.first.title and @param_changes.first.title[16..-1]
        @param_change.title = time_interval_str + @param_changes.first.title[16..-1]
      end

      # 生成FusionCharts的XML资料
      records = ParamChange.all( :order => "rec_date desc, id desc", :conditions => ["param_id = ? and rec_date >= ?", params[:param_id], Date.today - (value_of('data_num_in_fusioncharts').to_i-1)], :group => 'rec_date', :limit => value_of('data_num_in_fusioncharts').to_i )
      # 依照资料笔数的多寡来决定如何取图表中第一个值
      case records.size
        when 0
          last_record = ParamChange.last(:conditions => ["param_id = ?", params[:param_id]])
          last_value = last_record ? last_record.value : 0
        when 1
          last_value = ParamChange.all( :order => "id desc", :conditions => ["param_id = ?", params[:param_id]], :group => 'rec_date', :limit => 2 ).last.value
        else
          last_value = records.last.value
      end      
      build_fusion_charts_vars_from records, last_value 

    end    

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @param_change }
    end
  end

  # GET /param_changes/1/edit
  def edit
    @param_change = ParamChange.find(params[:id])
  end

  # POST /param_changes
  # POST /param_changes.xml
  def create   
    param_change_created = create_new_param_change

    respond_to do |format|
      if param_change_created
        # flash[:notice] = 'ParamChange was successfully created.'
        format.html { redirect_to :controller => 'main', :action => 'life_chart' }
        # format.html { redirect_to :action => 'new', :param_id => @param_change.param_id }
        format.xml  { render :xml => @param_change, :status => :created, :location => @param_change }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @param_change.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /param_changes/1
  # PUT /param_changes/1.xml
  def update
    @param_change = ParamChange.find(params[:id])

    respond_to do |format|
      if @param_change.update_attributes(params[:param_change])
        # flash[:notice] = 'ParamChange was successfully updated.'
        # 计算生活项目及类目得多少总分并写入数据库
        update_life_interest_values
        format.html { redirect_to :controller => 'main', :action => 'life_chart' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @param_change.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /param_changes/1
  # DELETE /param_changes/1.xml
  def destroy
    @param_change = ParamChange.find(params[:id])
    @param_change.destroy

    respond_to do |format|
      format.html { redirect_to :action => 'new', :param_id => params[:param_id] }
      format.xml  { head :ok }
    end
  end

end
