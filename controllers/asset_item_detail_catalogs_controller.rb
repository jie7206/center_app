class AssetItemDetailCatalogsController < ApplicationController
  # GET /asset_item_detail_catalogs
  # GET /asset_item_detail_catalogs.xml
  def index
    @asset_item_detail_catalogs = AssetItemDetailCatalog.all( :order => "order_num")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @asset_item_detail_catalogs }
    end
  end

  # GET /asset_item_detail_catalogs/1
  # GET /asset_item_detail_catalogs/1.xml
  def show
    @asset_item_detail_catalog = AssetItemDetailCatalog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @asset_item_detail_catalog }
    end
  end

  # GET /asset_item_detail_catalogs/new
  # GET /asset_item_detail_catalogs/new.xml
  def new
    @asset_item_detail_catalog = AssetItemDetailCatalog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @asset_item_detail_catalog }
    end
  end

  # GET /asset_item_detail_catalogs/1/edit
  def edit
    @asset_item_detail_catalog = AssetItemDetailCatalog.find(params[:id])
  end

  # POST /asset_item_detail_catalogs
  # POST /asset_item_detail_catalogs.xml
  def create
    @asset_item_detail_catalog = AssetItemDetailCatalog.new(params[:asset_item_detail_catalog])

    respond_to do |format|
      if @asset_item_detail_catalog.save
        flash[:notice] = 'AssetItemDetailCatalog was successfully created.'
        format.html { redirect_to(asset_item_detail_catalogs_url) }
        format.xml  { render :xml => @asset_item_detail_catalog, :status => :created, :location => @asset_item_detail_catalog }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @asset_item_detail_catalog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /asset_item_detail_catalogs/1
  # PUT /asset_item_detail_catalogs/1.xml
  def update
    @asset_item_detail_catalog = AssetItemDetailCatalog.find(params[:id])

    respond_to do |format|
      if @asset_item_detail_catalog.update_attributes(params[:asset_item_detail_catalog])
        flash[:notice] = 'AssetItemDetailCatalog was successfully updated.'
        format.html { redirect_to(asset_item_detail_catalogs_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @asset_item_detail_catalog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /asset_item_detail_catalogs/1
  # DELETE /asset_item_detail_catalogs/1.xml
  def destroy
    @asset_item_detail_catalog = AssetItemDetailCatalog.find(params[:id])
    begin
      @asset_item_detail_catalog.destroy
      # 为避免无法读取该类别下的资料，删除后，必须将类别改为自动写入
      update_asset_item_detail_catalog_ids_to_auto(params[:id])
    rescue
      flash[:notice] = '删除失败!可能因为无法删除自动写入类别!'
    end    

    respond_to do |format|
      format.html { redirect_to(asset_item_detail_catalogs_url) }
      format.xml  { head :ok }
    end
  end

  # 为避免无法读取该类别下的资料，删除后，必须将类别改为自动写入
  def update_asset_item_detail_catalog_ids_to_auto( id )
    AssetItemDetail.find_all_by_asset_item_detail_catalog_id(id).each do |a|
      a.update_attribute( :asset_item_detail_catalog_id, 8 )
    end
  end

  def order_up
    exe_order_up AssetItemDetailCatalog, params[:id]
    redirect_to :action => 'index'
  end
  
  def order_down
    exe_order_down AssetItemDetailCatalog, params[:id]
    redirect_to :action => 'index'
  end

end
