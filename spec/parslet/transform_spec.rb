require 'spec_helper'

require 'parslet'

describe Parslet::Transform do
  include Parslet
  
  let(:transform) { Parslet::Transform.new }
  attr_reader :transform
  before(:each) do
    @transform = Parslet::Transform.new
  end
  
  class A < Struct.new(:elt); end
  class B < Struct.new(:elt); end
  class C < Struct.new(:elt); end
  class Bi < Struct.new(:a, :b); end

  describe "delayed construction" do
    context "given simple(:x) => A.new(x)" do
      before(:each) do
        transform.rule(simple(:x)) { |d| A.new(d[:x]) }
      end

      it "should transform 'a' into A.new('a')" do
        transform.apply('a').should == A.new('a')
      end 
      it "should transform ['a', 'b'] into [A.new('a'), A.new('b')]" do
        transform.apply(['a', 'b']).should == 
          [A.new('a'), A.new('b')]
      end
    end
    context "given rules on {:a => simple(:x)} and {:b => :_x}" do
      before(:each) do
        transform.rule(:a => simple(:x)) { |d| A.new(d[:x]) }
        transform.rule(:b => simple(:x)) { |d| B.new(d[:x]) }
      end

      it "should transform {:d=>{:b=>'c'}} into d => B('c')" do
        transform.apply({:d=>{:b=>'c'}}).should == {:d => B.new('c')}
      end
      it "should transform {:a=>{:b=>'c'}} into A(B('c'))" do
        transform.apply({:a=>{:b=>'c'}}).should == A.new(B.new('c'))
      end
    end
    describe "pulling out subbranches" do
      before(:each) do
        transform.rule(:a => {:b => simple(:x)}, :d => {:e => simple(:y)}) { |d|
          Bi.new(*d.values_at(:x, :y))
        }
      end

      it "should yield Bi.new('c', 'f')" do
        transform.apply(:a => {:b => 'c'}, :d => {:e => 'f'}).should ==
          Bi.new('c', 'f')
      end 
    end
  end
  describe "dsl construction" do
    let(:transform) { Parslet::Transform.new do
        rule(simple(:x)) { A.new(x) }
      end 
    }
    
    it "should still evaluate rules correctly" do
      transform.apply('a').should == A.new('a')
    end 
  end
  describe "class construction" do
    class OptimusPrime < Parslet::Transform 
      rule(simple(:x)) { A.new(x) }
    end
    let(:transform) { OptimusPrime.new }
    
    it "should evaluate rules" do
      transform.apply('a').should == A.new('a')
    end 
  end
  
  context "when not using the bindings as hash, but as local variables" do
    before(:each) do
      transform.rule(simple(:x)) { A.new(x) }
    end
    
    it "should access the variables" do
      transform.apply('a').should == A.new('a')
    end 
  end
end