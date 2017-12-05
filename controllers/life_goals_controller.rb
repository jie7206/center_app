class LifeGoalsController < ApplicationController
  # GET /life_goals
  # GET /life_goals.xml
  def index
    #LifeGoal.update_all(["is_todo = ?",false])
    @life_goals = LifeGoal.all( :order => "order_num", :conditions => ["is_todo = ?",false] )
    @title = "生活目標設定表"
    @action_name = "index"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @life_goals }
    end
  end

  def todo_list
    @life_goals = LifeGoal.all( :order => "order_num", :conditions => ["is_todo = ? and is_pass = ?",true,false] )
    @title = "待辦事項一覽表"
    @action_name = "completed_todo_list"
    render :action => :index
  end

  def completed_todo_list
    @life_goals = LifeGoal.all( :order => "pass_date desc,order_num", :conditions => ["is_todo = ? and is_pass = ?",true,true] )
    @title = "待辦事項完成表"
    @action_name = "todo_list"
    render :action => :index
  end 

  # GET /life_goals/1
  # GET /life_goals/1.xml
  def show
    @life_goal = LifeGoal.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @life_goal }
    end
  end

  # GET /life_goals/new
  # GET /life_goals/new.xml
  def new
    last = LifeGoal.last
    @life_goal = LifeGoal.new(
      :is_show => true,
      :order_num => last.order_num+1,
      :param_id => last.param_id )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @life_goal }
    end
  end

  # GET /life_goals/1/edit
  def edit
    @life_goal = LifeGoal.find(params[:id])
  end

  # POST /life_goals
  # POST /life_goals.xml
  def create
    @life_goal = LifeGoal.new(params[:life_goal])
    
    respond_to do |format|
      if @life_goal.save
        format.html { redirect_to_index_or_todo_list }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @life_goal.errors, :status => :unprocessable_entity }
      end
    end    
  end

  # PUT /life_goals/1
  # PUT /life_goals/1.xml
  def update
    @life_goal = LifeGoal.find(params[:id])
    @life_goal.update_attributes(params[:life_goal])
    redirect_to_index_or_todo_list
  end

  def pass
    @life_goal = LifeGoal.find(params[:id])
    @life_goal.update_attribute(:is_pass,true)
    redirect_to(:controller => 'main', :action => 'life_chart')
  end

  # DELETE /life_goals/1
  # DELETE /life_goals/1.xml
  def destroy
    @life_goal = LifeGoal.find(params[:id])
    @life_goal.destroy
    redirect_to_index_or_todo_list
  end

  def prepare_order_params
    @ids = []
    @life_goal = LifeGoal.find(params[:id])
    if @life_goal.is_todo
      LifeGoal.find(:all, :order => "order_num", :conditions => ["is_todo = ? and is_pass = ?",true,false] ).each {|d| @ids << d.id}
    else
      LifeGoal.find(:all, :order => "order_num", :conditions => ["is_todo = ?",false] ).each {|d| @ids << d.id}
    end
    @ori_index = @ids.index(params[:id].to_i)
  end
  
  def life_goal_order_up
    prepare_order_params
    if @ori_index != 0 then
      @ids[@ori_index] = @ids[@ori_index-1]
      @ids[@ori_index-1] = params[:id].to_i
      @ids.each {|i| LifeGoal.find(i).update_attribute( :order_num, @ids.index(i)+1 )}
      redirect_to_index_or_todo_list_without_update_order_num
    end
  end
  
  def life_goal_order_down
    prepare_order_params
    if @ori_index != @ids.size-1 then
      @ids[@ori_index] = @ids[@ori_index+1]
      @ids[@ori_index+1] = params[:id].to_i
      @ids.each {|i| LifeGoal.find(i).update_attribute( :order_num, @ids.index(i)+1 )}
      redirect_to_index_or_todo_list_without_update_order_num
    end
  end  

  def redirect_to_index_or_todo_list_without_update_order_num
    if @life_goal.is_todo
      redirect_to :action => 'todo_list'
    else
      redirect_to :action => 'index'
    end
  end

  def redirect_to_index_or_todo_list
    if @life_goal.is_todo
      update_todo_list_order_num
      redirect_to :action => 'todo_list'
    else
      update_life_goal_order_num
      redirect_to :action => 'index'
    end
  end 

  def update_life_goal_attribute
    @life_goal = LifeGoal.find(params[:id])
    @life_goal.update_attribute(params[:field_name],params[:new_value])
    flash[:notice] = "已更新为#{params[:new_value]}"
    redirect_to_index_or_todo_list
  end

  # 将目标重置為全部沒有完成
  def reset_life_goals
    exe_reset_life_goals
    flash[:notice] = "目标重置完成！"
    redirect_to :action => 'index'
  end

  # 将目标重置為全不显示
  def unshow_all_life_goals
    exe_reset_life_goals
    LifeGoal.update_all( ["is_show = ?", false], ["is_todo = ?", false] )
    flash[:notice] = "目标全不显示完成！"
    redirect_to :action => 'index'
  end  

  # 清空全部的目标记录
  def destroy_all_life_goals
    LifeGoal.destroy_all ["is_todo = ?", false]
    redirect_to :action => 'index'
  end

  # 清空全部的待办记录
  def destroy_all_life_todos
    LifeGoal.destroy_all ["is_todo = ? and is_pass = ?",true,false]
    redirect_to :action => 'index'
  end

end
