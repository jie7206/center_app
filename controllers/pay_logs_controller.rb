class PayLogsController < ApplicationController
  # GET /pay_logs
  # GET /pay_logs.xml
  before_filter :check_if_your_pay_log, :only => [ :edit, :update, :destroy ]
  
  def index
    @pay_logs = PayLog.all( :order => "created_at desc" )
    
    @pay_logs_start_calculate_id = Param.find_by_name('pay_logs_start_calculate_id').value.to_i
    @remain_budget = Param.find_by_name('pay_logs_start_budget').value.to_f

    pay_sum = Param.find_by_sql("select sum(amount) as amount from pay_logs where id > #{@pay_logs_start_calculate_id} and is_received = 't'").first.amount.to_f
    @remain_budget -= pay_sum if pay_sum

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pay_logs }
    end
  end

  # GET /pay_logs/1
  # GET /pay_logs/1.xml
  def show
    @pay_log = PayLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @pay_log }
    end
  end

  # GET /pay_logs/new
  # GET /pay_logs/new.xml
  def new
    @pay_log = PayLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pay_log }
    end
  end

  # GET /pay_logs/1/edit
  def edit
    @pay_log = PayLog.find(params[:id])
  end

  # POST /pay_logs
  # POST /pay_logs.xml
  def create
    @pay_log = PayLog.new(params[:pay_log])

    respond_to do |format|
      if @pay_log.save
        flash[:notice] = 'PayLog was successfully created.'
        format.html { redirect_to :action => 'index' }
        format.xml  { render :xml => @pay_log, :status => :created, :location => @pay_log }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pay_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pay_logs/1
  # PUT /pay_logs/1.xml
  def update
    @pay_log = PayLog.find(params[:id])
    if Account.find_by_member_id(session[:login_mid]).is_accountant
      if params[:pay_log][:is_received] && params[:pay_log][:is_received] == '1'
        params[:pay_log][:manager] = Member.find(session[:login_mid]).name
      else
        params[:pay_log][:manager] = ""
      end
    end
    respond_to do |format|
      if @pay_log.update_attributes(params[:pay_log])
        
        flash[:notice] = 'PayLog was successfully updated.'
        format.html { redirect_to :action => 'index' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pay_log.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pay_logs/1
  # DELETE /pay_logs/1.xml
  def destroy
    @pay_log = PayLog.find(params[:id])
    @pay_log.destroy

    respond_to do |format|
      format.html { redirect_to(pay_logs_url) }
      format.xml  { head :ok }
    end
  end
end
