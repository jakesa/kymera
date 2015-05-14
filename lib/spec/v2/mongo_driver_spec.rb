require_relative '../../../lib/kymera'

describe Kymera::MongoDriver do


  it 'should initialize with defaults' do
    driver = Kymera::MongoDriver.new
    expect(driver.collection).to_not eq nil
    expect(driver.db_client).to_not eq nil
  end

  it 'should write the json log to the database' do
    driver = Kymera::MongoDriver.new
    driver.write_log(JSON.generate({:name => "jake"}))
    expect(driver.exists?({:name => "jake"})).to eq true
  end

  it 'should return false if a document does not exist' do
    driver = Kymera::MongoDriver.new
    expect(driver.exists?({:name => "adsfa"})).to eq false
  end

  it "should remove the document with the specified hash value" do
    driver = Kymera::MongoDriver.new
    driver.write_log(JSON.generate({:name => "jake"}))
    driver.remove(:name => "jake")
    expect(driver.exists?(:name => "jake")).to eq false
  end

  it "should get back the list of documents in the specified collection" do
    driver = Kymera::MongoDriver.new
    driver.write_log(JSON.generate({:name => "jake"}))
    driver = Kymera::MongoDriver.new
    docs = driver.get_collection("default_db")
    expect(docs[0]["name"]).to eq "jake"
  end

  it 'should remove all of the documents in the nodes collection' do
    driver = Kymera::MongoDriver.new
    docs = driver.get_collection('nodes')

  end

end