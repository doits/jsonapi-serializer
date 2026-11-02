require 'spec_helper'

RSpec.describe FastJsonapi do
  describe '.call_proc' do
    it 'passes only as many params as the proc declares' do
      expect(described_class.call_proc(proc { 0 }, :a, :b)).to eq(0)
      expect(described_class.call_proc(proc { |a| [a] }, :a, :b, :c)).to eq([:a])
      expect(described_class.call_proc(->(a, b) { [a, b] }, :a, :b, :c)).to eq(%i[a b])
      expect(described_class.call_proc(proc { |a, b, c| [a, b, c] }, :a, :b, :c, :d)).to eq(%i[a b c])
    end

    it 'passes all params when the proc declares more' do
      expect(described_class.call_proc(proc { |a, b, c| [a, b, c] }, :a, :b)).to eq([:a, :b, nil])
      expect { described_class.call_proc(->(a, b, c) { [a, b, c] }, :a, :b) }.to raise_error(ArgumentError)
    end

    it 'passes only the first param to a proc of negative arity' do
      expect(described_class.call_proc(:to_s.to_proc, 1, :b)).to eq('1')
      expect(described_class.call_proc(proc { |*a| a }, :a, :b)).to eq([:a])
    end

    it 'reads the parameters of a proc only once' do
      pr = proc { |a, b| [a, b] }
      allow(pr).to receive(:parameters).and_call_original

      2.times { expect(described_class.call_proc(pr, :a, :b, key: :c)).to eq(%i[a b]) }
      expect(pr).to have_received(:parameters).once
    end
  end

  describe '.call_instance_exec' do
    let(:base) { 'base' }

    it 'runs the proc on the base with as many params as it declares' do
      expect(described_class.call_instance_exec(base, proc { |a| [self, a] }, :a, :b)).to eq(['base', :a])
      expect(described_class.call_instance_exec(base, proc { |a, b| [self, a, b] }, :a, :b, :c)).to eq(['base', :a, :b])
      expect(described_class.call_instance_exec(base, proc { |a, b, c| [self, a, b, c] }, :a, :b))
        .to eq(['base', :a, :b, nil])
    end

    it 'passes only the first param to a proc of negative arity' do
      expect(described_class.call_instance_exec(base, proc { |*a| [self, a] }, :a, :b)).to eq(['base', [:a]])
    end
  end
end
