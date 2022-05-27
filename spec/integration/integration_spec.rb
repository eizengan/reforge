# frozen_string_literal: true

RSpec.describe "Transforming and memoizing data" do
  subject(:results) { ExampleTransformation.call(*sources) }

  let(:current_time) { Time.now }
  let(:sources) do
    [
      { order_date_string: "2022-01-01", fn: "Ali", ln: "Alison", account_id: 1  },
      { order_date_string: "2022-01-03", fn: "Cam", ln: "Camson", account_id: 1  },
      { order_date_string: "2022-01-02", fn: "Ben", ln: "Benson", account_id: 1  },
      { order_date_string: "2022-01-03", fn: "Deb", ln: "Debson", account_id: 2  },
      { order_date_string: "2022-01-05", fn: "Eli", ln: "Elison", account_id: 1  },
      { order_date_string: "2022-01-07", fn: "Fry", ln: "Fryson", account_id: 999  }
    ]
  end

  before { allow(Time).to receive(:now).and_return(current_time) }

  class Account
    attr_reader :id

    def initialize(id)
      @id = id
    end

    def self.find(id)
      if [1, 2].include?(id)
        Account.new(id)
      else
        nil
      end
    end
  end

  class ExampleTransformation < Reforge::Transformation
    extract :ordered_at, from: ->(s) { Date.parse(s[:order_date_string]) }
    extract %i[attn first_name], from: { key: :fn }
    extract %i[attn last_name], from: { key: :ln }
    extract :account, from: ->(s) { Account.find(s[:account_id]) }, memoize: { by: { key: :account_id } }
    extract :processed_at, from: -> { Time.now }, memoize: :first
  end


  it "extracts data from the source" do
    expect(results).to contain_exactly(
      { ordered_at: Date.new(2022, 1, 1), attn: { first_name: "Ali", last_name: "Alison" }, account: an_object_having_attributes(class: Account, id: 1), processed_at: current_time },
      { ordered_at: Date.new(2022, 1, 2), attn: { first_name: "Ben", last_name: "Benson" }, account: an_object_having_attributes(class: Account, id: 1), processed_at: current_time },
      { ordered_at: Date.new(2022, 1, 3), attn: { first_name: "Cam", last_name: "Camson" }, account: an_object_having_attributes(class: Account, id: 1), processed_at: current_time },
      { ordered_at: Date.new(2022, 1, 3), attn: { first_name: "Deb", last_name: "Debson" }, account: an_object_having_attributes(class: Account, id: 2), processed_at: current_time },
      { ordered_at: Date.new(2022, 1, 5), attn: { first_name: "Eli", last_name: "Elison" }, account: an_object_having_attributes(class: Account, id: 1), processed_at: current_time },
      { ordered_at: Date.new(2022, 1, 7), attn: { first_name: "Fry", last_name: "Fryson" }, account: nil, processed_at: current_time }
    )
  end

  it "memoizes data" do
    expect(Account).to receive(:find).exactly(3).times
    expect(Account).to receive(:find).once.with(1)
    expect(Account).to receive(:find).once.with(2)
    expect(Account).to receive(:find).once.with(999)

    results

    expect(Time).to have_received(:now).once
  end
end
