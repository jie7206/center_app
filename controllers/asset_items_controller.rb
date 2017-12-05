class AssetItemsController < ApplicationController
  # GET /asset_items
  # GET /asset_items.xml
  def index
    get_asset_belongs_to_id
    @asset_items = AssetItem.all( :include => :asset, :order => "asset_id,ntd_amount desc,title", :conditions => ["asset_belongs_to_id = ?", @asset_belongs_to_id] )
    
    case @asset_belongs_to_id.to_i
      when 1
        # 計算家庭資產報表參數
        prepare_my_asset_var
        # 更新各国货币的汇率 + 自动更新资产总值
        update_exchange_rates
        # 从网路(安居客+赶集网)获取最新房价资讯 + 自动更新资产总值
        @today_house_price_str = get_today_house_price_str
      when 2
        # 計算中心資產報表參數
        prepare_center_asset_var
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @asset_items }
    end
  end

  # GET /asset_items/1
  # GET /asset_items/1.xml
  def show
    @asset_item = AssetItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @asset_item }
    end
  end

  # GET /asset_items/new
  # GET /asset_items/new.xml
  def new
    @asset_item = AssetItem.new
    @asset_item.asset_belongs_to_id = get_asset_belongs_to_id

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @asset_item }
    end
  end

  # GET /asset_items/1/edit
  def edit
    @asset_item = AssetItem.find(params[:id])
  end

  # POST /asset_items
  # POST /asset_items.xml
  def create
    @asset_item = AssetItem.new(params[:asset_item])

    respond_to do |format|
      if @asset_item.save
        flash[:notice] = 'AssetItem was successfully created.'
        format.html { redirect_to(asset_items_url) }
        format.xml  { render :xml => @asset_item, :status => :created, :location => @asset_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @asset_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /asset_items/1
  # PUT /asset_items/1.xml
  def update
    @asset_item = AssetItem.find(params[:id])
    ori_amount = @asset_item.amount

    respond_to do |format|
      if @asset_item.update_attributes(params[:asset_item])
        auto_create_or_update_asset_item_detail( @asset_item.id, @asset_item.amount, ori_amount ) if ori_amount != @asset_item.amount
        flash[:notice] = 'AssetItem was successfully updated'
        format.html { redirect_to(asset_items_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @asset_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /asset_items/1
  # DELETE /asset_items/1.xml
  def destroy
    @asset_item = AssetItem.find(params[:id])
    @asset_item.destroy

    respond_to do |format|
      format.html { redirect_to(asset_items_url) }
      format.xml  { head :ok }
    end
  end
  
  def xml_list
    respond_to do |format|
        format.html do
          redirect_to :action => :index
        end
        format.xml  do 
          xml_result = ""
          Asset.all( :include => :asset_items ).each do |a|
            xml_result += "<#{a.code}>\n"
            a.asset_items.each do |i|
              xml_result += "<item title=\"#{i.title}\" amount=\"#{i.amount}\" currency=\"#{i.currency}\"/>\n"
            end
            xml_result += "</#{a.code}>\n"
          end
          xml_result = '<?xml version="1.0" encoding="utf-8"?><data>' + xml_result + '</data>'
        	render :text => xml_result
     	end
    end  	    
  end      
  
end  
