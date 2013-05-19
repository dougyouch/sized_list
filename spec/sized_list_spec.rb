require 'spec_helper'

describe SizedList do
  it "should store a limited number of items" do
    list = SizedList.new 5
    5.times { |i| list.set "item-#{i}", 1 }
    list.size.should == 5
    100.times { |i| list.set "new-item-#{i}", 1 }
    list.size.should == 5
    list['new-item-99'].should == 1
  end

  it "should keep the most recent used item at the top of the list" do
    list = SizedList.new 5
    list['a'] = 1
    list['b'] = 1
    list['c'] = 1
    list['d'] = 1
    list['e'] = 1
    list.keys.should == ['e', 'd', 'c', 'b', 'a']

    list['b'].should == 1
    list.keys.should == ['b', 'e', 'd', 'c', 'a']

    list['b'].should == 1
    list.keys.should == ['b', 'e', 'd', 'c', 'a']
  end

  it "should remove the least accessed" do
    list = SizedList.new 5
    list['a'] = 1
    list['b'] = 1
    list['c'] = 1
    list['d'] = 1
    list['e'] = 1
    list.keys.should == ['e', 'd', 'c', 'b', 'a']

    list['a'].should == 1
    list.keys.should == ['a', 'e', 'd', 'c', 'b']

    list['new'] = 1
    list.keys.should == ['new', 'a', 'e', 'd', 'c']

    list['d'].should == 1
    list.keys.should == ['d', 'new', 'a', 'e', 'c']

    list['new2'] = 1
    list.keys.should == ['new2', 'd', 'new', 'a', 'e']
  end
end
