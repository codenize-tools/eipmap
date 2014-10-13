describe Eipmap do
  let(:eips) do
    eips = describe_addresses["vpc"].keys.zip(
             describe_network_interface.map {|interface_id, private_ips|
               { network_interface_id: interface_id,
                 private_ip_address: private_ips.first}})
    Hash[*eips.flatten]
  end

  context "when no association" do
    it do
      dsl = <<-EOS
domain "vpc" do
<%- eips.each do |public_ip, attrs| -%>
  ip "<%= public_ip %>"
<%- end -%>
end
      EOS

      result = apply { dsl }
      expect(result).to be_falsey
      expect(describe_addresses["vpc"].values).to match_array [{}, {}, {}]
    end
  end

  context "when associate" do
    it do
      dsl = <<-EOS
domain "vpc" do
<%- eips.each do |public_ip, attrs| -%>
  ip "<%= public_ip %>", <%= attrs.inspect %>
<%- end -%>
end
      EOS

      result = apply { dsl }
      expect(result).to be_truthy
      expect(describe_addresses["vpc"]).to eq eips
    end
  end

  context "when disassociate" do
    before do
      apply {
        <<-EOS
domain "vpc" do
<%- eips.each do |public_ip, attrs| -%>
  ip "<%= public_ip %>", <%= attrs.inspect %>
<%- end -%>
end
        EOS
      }
    end

    it do
      dsl = <<-EOS
domain "vpc" do
<%- eips.each do |public_ip, attrs| -%>
  ip "<%= public_ip %>"
<%- end -%>
end
      EOS

      result = apply { dsl }
      expect(result).to be_truthy
      expect(describe_addresses["vpc"].values).to match_array [{}, {}, {}]
    end
  end
end
