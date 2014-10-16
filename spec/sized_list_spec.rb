require 'spec_helper'

describe SizedList do
  it "should store a limited number of items" do
    list = SizedList.new 5
    5.times { |i| list.set "item-#{i}", 1 }
    list.size.should == 5
    100.times { |i| list.set "new-item-#{i}", 1 }
    list.size.should == 5
    list.evictions .should == 100
    list['new-item-99'].should == 1
  end

  it "should keep the most recent used item at the top of the list" do
    list = SizedList.new 5
    list['a'] = 1
    list['b'] = 1
    list['c'] = 1
    list['d'] = 1
    list['e'] = 1
    list.keys.should == ['a', 'b', 'c', 'd', 'e']

    list['b'].should == 1
    list.keys.should == ['a', 'c', 'd', 'e', 'b']
    list.evictions.should == 0
    list.misses.should == 0
    list.hits.should == 1
    list.writes.should == 5

    list['b'].should == 1
    list.keys.should == ['a', 'c', 'd', 'e', 'b']
    list.evictions.should == 0
    list.misses.should == 0
    list.hits.should == 2

    list['not_here'].should be_nil
    list.evictions.should == 0
    list.misses.should == 1
    list.hits.should == 2
  end

  it "should remove the least accessed" do
    list = SizedList.new 5
    list.enable_time_based_stats = true
    list['a'] = 1
    list['b'] = 1
    list['c'] = 1
    list['d'] = 1
    list['e'] = 1
    list.keys.should == ['a', 'b', 'c', 'd', 'e']
    list.writes.should == 5

    list['a'].should == 1
    list.keys.should == ['b', 'c', 'd', 'e', 'a']
    list.evictions.should == 0

    list['new'] = 1
    list.evicted?.should be_true
    list['new'] = 1
    list.evicted?.should be_false
    list.keys.should == ['c', 'd', 'e', 'a', 'new']
    list.evictions.should == 1
    list.writes.should == 6

    list['d'].should == 1
    list.keys.should == ['c', 'e', 'a', 'new', 'd']
    list.evictions.should == 1

    list['new2'] = 1
    list.keys.should == ['e', 'a', 'new', 'd', 'new2']
    list.evictions.should == 2
  end
end
