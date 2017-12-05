class MemberReportsController < ApplicationController

  # 显示每月报表
  def month_report
    @year = params[:year] || Date.today.year
    @member_reports = MemberReport.year_report( @year )
    @members = Member.all( :select => "id, name, mobile", :conditions => [ "career != 99 and area_id = ?", value_of('default_area_id') ] )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @member_reports }
    end
  end

  # GET /member_reports
  # GET /member_reports.xml
  def index
    @member_reports = params[:showall] ? MemberReport.all(:order => "rec_date desc") : MemberReport.month_report
    @top_record_id = @member_reports.first.id

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @member_reports }
    end
  end

  # GET /member_reports/1
  # GET /member_reports/1.xml
  def show
    @member_report = MemberReport.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @member_report }
    end
  end

  # GET /member_reports/new
  # GET /member_reports/new.xml
  def new
    @member_report = MemberReport.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @member_report }
    end
  end

  # GET /member_reports/1/edit
  def edit
    @member_report = MemberReport.find(params[:id])
  end

  # POST /member_reports
  # POST /member_reports.xml
  def create
    @member_report = MemberReport.new(params[:member_report])

    respond_to do |format|
      if @member_report.save
        flash[:notice] = 'MemberReport was successfully created.'
        format.html { redirect_to(@member_report) }
        format.xml  { render :xml => @member_report, :status => :created, :location => @member_report }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @member_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /member_reports/1
  # PUT /member_reports/1.xml
  def update
    @member_report = MemberReport.find(params[:id])

    respond_to do |format|
      if @member_report.update_attributes(params[:member_report])
        flash[:notice] = 'MemberReport was successfully updated.'
        format.html { redirect_to(@member_report) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @member_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /member_reports/1
  # DELETE /member_reports/1.xml
  def destroy
    @member_report = MemberReport.find(params[:id])
    @member_report.destroy

    respond_to do |format|
      format.html { redirect_to(member_reports_url) }
      format.xml  { head :ok }
    end
  end

  def auto_create
    # 依照会员在本月参加活动的次数，自动更新会员的所属类别
    update_all_members_classification_by_histories_count_month
    # 更新或新建人员分布报表
    update_or_create_member_report
    redirect_to :action => 'month_report'
  end

end