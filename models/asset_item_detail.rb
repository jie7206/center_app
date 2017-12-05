class AssetItemDetail < ActiveRecord::Base

  belongs_to :asset_item
  belongs_to :asset_item_detail_catalog
  before_validation :check_if_balance_is_zero, :set_accounting_date
  after_create :update_asset_item_amount
  validates_numericality_of :change_amount, :balance, :message => '收支變化和資產餘額的值只能是數字!'

  def check_if_balance_is_zero
    if !self.balance or self.balance.nil?
      self.balance = AssetItem.find(self.asset_item_id).amount + self.change_amount
    elsif !self.change_amount or self.change_amount.nil?
      self.change_amount = self.balance - AssetItem.find(self.asset_item_id).amount
    end
  end

  def set_accounting_date
    self.accounting_date = Date.today if !self.accounting_date
  end

  def update_asset_item_amount
    AssetItem.find(self.asset_item_id).update_attribute(:amount, self.balance)
  end

end
