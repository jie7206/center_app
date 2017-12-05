class AssetItemDetailCatalog < ActiveRecord::Base

	has_many :asset_item_details
	before_validation :set_order_num
	before_destroy :dont_destroy_auto_insert

  def set_order_num
    self.order_num = 99 if not self.order_num
  end

	def dont_destroy_auto_insert
		raise "无法删除自动写入类别!" if id == 8
	end

  def total_amount
    result = AssetItemDetail.find_by_sql("SELECT SUM(change_amount) AS total_amount FROM asset_item_details WHERE asset_item_detail_catalog_id=#{self.id}")[0][:total_amount]
    if result
      return result.to_f
    else
      return 0
    end
  end

end
