require File.expand_path '../spec_helper.rb', __FILE__

records = [
      {department: 'ruby', timespan: Time.new(2015,1,1,16,0,0, "+00:00").to_f},
      {department: 'ruby', timespan: Time.new(2015,1,2,16,20,0, "+00:00").to_f},
      {department: 'ruby', timespan: Time.new(2015,1,3,16,59,0, "+00:00").to_f},
      {department: 'ruby', timespan: Time.new(2015,2,4,20,15,0, "+00:00").to_f},
      {department: 'ruby', timespan: Time.new(2015,4,5,20,15,0, "+00:00").to_f},
      {department: 'python', timespan: Time.new(2015,6,1,20,15,0, "+00:00").to_f},
      {department: 'python', timespan: Time.new(2015,7,1,20,35,0, "+00:00").to_f},
      {department: 'python', timespan: Time.new(2015,7,1,23,35,0, "+00:00").to_f}
    ] 

describe Requests do
  dataset = DB.from(:hh_requests)
  
  before(:all) {  
    dataset.delete
    dataset.multi_insert(records)
  }
  
  let(:requests) {
    Requests.new(dataset)
  }
  
  it "should bring all requests" do
    expect(requests.all.count).to eq(8)
  end
  
  it "should group and count by department" do
    expect(requests.department_group_count.count).to eq(2)
    expect(requests.department_group_count[0][0]).to eq('python')
    expect(requests.department_group_count[0][1]).to eq(3)
    expect(requests.department_group_count[1][0]).to eq('ruby')
    expect(requests.department_group_count[1][1]).to eq(5)
  end
  
  it "should group by department by hour of the day" do
    expect(requests.departments_by_hour[0]['department']).to eq('python')
    expect(requests.departments_by_hour[0]['value']['2015-01-01 20:00:00 +0000']).to eq(2)
    expect(requests.departments_by_hour[0]['value']['2015-01-01 23:00:00 +0000']).to eq(1)
    
    expect(requests.departments_by_hour[1]['department']).to eq('ruby')
    expect(requests.departments_by_hour[1]['value']['2015-01-01 16:00:00 +0000']).to eq(3)
    expect(requests.departments_by_hour[1]['value']['2015-01-01 20:00:00 +0000']).to eq(2)
  end
end