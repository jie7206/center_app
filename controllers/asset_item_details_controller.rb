class AssetItemDetailsController < ApplicationController
  # GET /asset_item_details
  # GET /asset_item_details.xml
  def index

    if params[:catalog_id]
      @asset_item_details = AssetItemDetail.all( :limit => 100, :order => "created_at desc", :include => :asset_item, :conditions => ["asset_item_detail_catalog_id = ?", params[:catalog_id]] )
    else
      @asset_item_details = AssetItemDetail.all( :limit => 100, :order => "created_at desc", :include => :asset_item )
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @asset_item_details }
    end
  end

  # GET /asset_item_details/1
  # GET /asset_item_details/1.xml
  def show
    @asset_item_detail = AssetItemDetail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @asset_item_detail }
    end
  end

  # GET /asset_item_details/new
  # GET /asset_item_details/new.xml
  def new
    @asset_item_detail = AssetItemDetail.new
    if params[:asset_item_id]
      @asset_item_details = AssetItemDetail.find(:all, :order => "id desc", :limit => value_of('data_num_in_fusioncharts').to_i, :conditions => ["asset_item_id = ?", params[:asset_item_id]] )
      @asset_item_details.reverse!
    end
=begin
    n = 0
    AssetItemDetail.all.each do |d|
      d.update_attribute(:accounting_date, d.created_at.to_date)
      n += 1
    end
    flash[:notice] = "#{n}笔资料已更新accounting_date属性!"
=end
    # 生成FusionCharts的XML资料
    if @asset_item_details.first
      build_fusion_charts_vars_from @asset_item_details, @asset_item_details.first.balance, 'balance', 'accounting_date'
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @asset_item_detail }
    end
  end

  # GET /asset_item_details/1/edit
  def edit
    @asset_item_detail = AssetItemDetail.find(params[:id])
  end

  # POST /asset_item_details
  # POST /asset_item_details.xml
  def create
    params[:asset_item_detail][:balance].gsub!(',','') # 去掉金钱的逗点
    @asset_item_detail = AssetItemDetail.new(params[:asset_item_detail])

    respond_to do |format|
      if @asset_item_detail.save
        # 当我的家庭流动资产变化的时候，自动更新Param中流动资产的总值，并自动加入一笔ParamChange以追踪变化记录
        update_my_assets_and_insert_change_record if @asset_item_detail.asset_item.asset_belongs_to_id == 1
        flash[:notice] = 'created!'
        format.html { redirect_to :controller => :asset_item_details, :action => :new, :asset_item_id => @asset_item_detail.asset_item_id }
        format.xml  { render :xml => @asset_item_detail, :status => :created, :location => @asset_item_detail }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @asset_item_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /asset_item_details/1
  # PUT /asset_item_details/1.xml
  def update
    @asset_item_detail = AssetItemDetail.find(params[:id])

    respond_to do |format|
      if @asset_item_detail.update_attributes(params[:asset_item_detail])
        flash[:notice] = 'updated!'
        format.html { redirect_to :controller => :asset_item_details, :action => :new, :asset_item_id => @asset_item_detail.asset_item_id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @asset_item_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /asset_item_details/1
  # DELETE /asset_item_details/1.xml
  def destroy
    @asset_item_detail = AssetItemDetail.find(params[:id])
    asset_item_id = @asset_item_detail.asset_item_id
    @asset_item_detail.destroy

    respond_to do |format|
      format.html { redirect_to(:action => :new, :asset_item_id => asset_item_id) }
      format.xml  { head :ok }
    end
  end
end
