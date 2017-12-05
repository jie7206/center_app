class AssetItem < ActiveRecord::Base

  belongs_to :asset
  has_many :asset_item_details, :dependent => :destroy
  before_save :set_ntd_amount
  validates_presence_of :amount, :message=> '金额不能空白!'

  def to_ntd
		case currency
			when 'NTD'
			  exchange_rate = value_of('exchange_rates_NTD').to_f
			when 'MCY'
			  exchange_rate = value_of('exchange_rates_MCY').to_f
			when 'USD'
			  exchange_rate = value_of('exchange_rates_USD').to_f
			when 'KRW'
			  exchange_rate = value_of('exchange_rates_KRW').to_f
	  end
	  return (amount*exchange_rate).to_i	
  end

  def set_ntd_amount
	  self.ntd_amount = self.to_ntd
  end  

  def to_mcy
		case currency
			when 'NTD'
			  exchange_rate = value_of('exchange_rates_NTD').to_f / value_of('exchange_rates_MCY').to_f
			when 'MCY'
			  exchange_rate = 1
			when 'USD'
			  exchange_rate = value_of('exchange_rates_USD').to_f / value_of('exchange_rates_MCY').to_f
			when 'KRW'
			  exchange_rate = value_of('exchange_rates_KRW').to_f / value_of('exchange_rates_MCY').to_f
	  end
	  return amount*exchange_rate
  end

  def self.total_money_for_goal
  	result = 0
  	all(:conditions => [ "is_save_for_goal = ?", true ]).each do |asset_item|
  		result += asset_item.to_ntd.to_i
  	end
  	return result
  end

end