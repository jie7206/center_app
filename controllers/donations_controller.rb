class DonationsController < ApplicationController
  # GET /donations
  # GET /donations.xml
  def index
    build_donation_rec
    session[:donation_data] = nil

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @donations }
    end
  end

  def build_donation_rec
    order_str = "catalog_id,accounting_date desc"
    if params[:data_field] and params[:data_value]
      @donations = Donation.all( :limit => 300, :order => "created_at desc, catalog_id", :include => :member, :conditions => ["#{params[:data_field]} = ?", params[:data_value]] )
    else
      @donations = Donation.all( :order => order_str, :include => :member )
    end
    order_index_field @donations
  end

  # GET /donations/1
  # GET /donations/1.xml
  def show
    @donation = Donation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @donation }
    end
  end

  # GET /donations/new
  # GET /donations/new.xml
  def new
    @donation = Donation.new
    @donation_member_name = ""
=begin    
    if !session[:donation_data].nil?
      @donation.member_id =         session[:donation_data][:member_id]
      @donation.catalog_id =        session[:donation_data][:catalog_id]
      @donation.accounting_date =   session[:donation_data][:accounting_date]
      @donation.amount =            session[:donation_data][:amount]
      @donation.note =              session[:donation_data][:note]
      @donation_member_name =       session[:donation_data][:member_name]
      @donation.title = ""
      @donation.id = nil
    end    
=end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @donation }
    end
  end

  # GET /donations/1/edit
  def edit
    @donation = Donation.find(params[:id])
    @donation_member_name = @donation.member.name
  end

  # POST /donations
  # POST /donations.xml
  def create
    @donation = Donation.new(params[:donation])
    member = Member.find_by_name(params[:member_name])
    @donation.member_id = member.id if member

    respond_to do |format|
      if member and @donation.save
        #session[:donation_data] = @donation
        #session[:donation_data][:member_name] = params[:member_name]
        flash[:notice] = "姓名為#{params[:member_name]}且ID為#{@donation.id.to_s}的奉獻紀錄已新增成功!"
        format.html { redirect_to :action => "new" }
        format.xml  { render :xml => @donation, :status => :created, :location => @donation }
      elsif not member
        flash[:notice] = "找不到該會員基本資料，所以無法新增!"
        format.html { render :action => "new" }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @donation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /donations/1
  # PUT /donations/1.xml
  def update
    @donation = Donation.find(params[:id])
    member = Member.find_by_name(params[:member_name])
    @donation.member_id = member.id if member

    respond_to do |format|
      if member and @donation.update_attributes(params[:donation])
        flash[:notice] = 'Donation was successfully updated.'
        format.html { redirect_to(donations_url) }
        format.xml  { head :ok }
      elsif not member
        flash[:notice] = "找不到該會員基本資料，所以無法更新!"
        format.html { render :action => "new" }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @donation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /donations/1
  # DELETE /donations/1.xml
  def destroy
    @donation = Donation.find(params[:id])
    @donation.destroy

    respond_to do |format|
      format.html { redirect_to(donations_url) }
      format.xml  { head :ok }
    end
  end
end
