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

  context "when swap association" do
    let(:eips_with_one_assoc) do
      eips.each_with_index do |(public_ip, attrs), i|
        attrs.clear unless i.zero?
      end

      eips
    end

    let(:swapped_eips_with_one_assoc) do
      public_ips = eips_with_one_assoc.keys
      swapped = {}
      mapping = {0 => 1, 1 => 0}

      eips_with_one_assoc.each_with_index do |(public_ip, attrs), i|
        ip_idx = mapping.fetch(i, i)
        ip = public_ips[ip_idx]
        swapped[public_ip] = eips_with_one_assoc[ip]
      end

      swapped
    end

    before do
      apply {
        <<-EOS
domain "vpc" do
<%- eips_with_one_assoc.each do |public_ip, attrs| -%>
  ip "<%= public_ip %>", <%= attrs.inspect %>
<%- end -%>
end
        EOS
      }
    end

    it do
      dsl = <<-EOS
domain "vpc" do
<%- swapped_eips_with_one_assoc.each do |public_ip, attrs| -%>
  ip "<%= public_ip %>", <%= attrs.inspect %>
<%- end -%>
end
      EOS

      result = apply { dsl }
      expect(result).to be_truthy
      expect(describe_addresses["vpc"]).to eq swapped_eips_with_one_assoc
    end
  end

  context "when dry-run" do
    subject { client(dry_run: true) }

    it do
      dsl = <<-EOS
domain "vpc" do
<%- eips.each do |public_ip, attrs| -%>
  ip "<%= public_ip %>", <%= attrs.inspect %>
<%- end -%>
end
      EOS

      result = apply(subject) { dsl }
      expect(result).to be_falsey
      expect(describe_addresses["vpc"].values).to match_array [{}, {}, {}]
    end
  end
end
