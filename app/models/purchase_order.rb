class PurchaseOrder < ApplicationRecord
  belongs_to :supplier
  has_many :purchase_order_items, dependent: :destroy
  has_many :products, through: :purchase_order_items

  accepts_nested_attributes_for :purchase_order_items, reject_if: :all_blank, allow_destroy: true

  enum :status, { pending: 0, sent: 1, received: 2, cancelled: 3 }

  validates :supplier, presence: true
end
