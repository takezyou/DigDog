class Create < ApplicationRecord
  attr_accessor :image, :name, :port, :request_memory, :limit_memory, :request_cpu, :limit_cpu

  validates :image, presence: true
  validates :name, presence: { message: ":必須項目です" }, format: {
    with: /\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/,
    message: "で使える文字は小文字の英数字、「-」または「.」のみです。また、最初と最後の文字が英数字である必要があります。(入力された値:%{value})"}
  validates :port,
    presence: { message: ":必須項目です" },
    numericality: { only_integer: true,
                    greater_than: 0,
                    less_than_or_equal_to: 65535,
                    message: "の値は1〜65535の範囲で入力してください。(入力された値:%{value})" }
  validates :request_memory,
    presence: { message: ":必須項目です" },
    numericality: { greater_than: 0,
                    message: "の値は整数で入力してください。(入力された値:%{value})" }
  validates :limit_memory,
    presence: { message: ":必須項目です" },
    numericality: { greater_than: 0,
                    message: "の値は整数で入力してください。(入力された値:%{value})" }
  validates :request_cpu,
    presence: { message: ":必須項目です" },
    numericality: { greater_than: 0,
                    message: "の値は小数で入力してください。(入力された値:%{value})" }
  validates :limit_cpu,
    presence: { message: ":必須項目です" },
    numericality: { greater_than: 0,
                    message: "の値は小数で入力してください。(入力された値:%{value})" }
end
