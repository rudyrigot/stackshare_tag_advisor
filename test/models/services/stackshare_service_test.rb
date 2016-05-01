require 'test_helper'

class StackShareServiceTest < ActiveSupport::TestCase

  setup do
    # Stubbing the /stacks/tags requests
    tags_page_1_json = %([{"id":1,"name":"saas"},{"id":2,"name":"cloud-computing"},{"id":3,"name":"paas"},{"id":4,"name":"big-data"}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=&page=1").to_return(body: tags_page_1_json)
    tags_page_2_json = %([{"id":5,"name":"ventures-for-good"},{"id":6,"name":"consumer-lending"},{"id":7,"name":"finance-technology"},{"id":8,"name":"social-media"}])
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=&page=2").to_return(body: tags_page_2_json)
    stub_request(:get, "https://api.stackshare.io/v1/stacks/tags?access_token=&page=3").to_return(status: 404)

    # Stubbing the /tools/layers requests
    layers_page_json = %([{"id":1,"name":"Application and Data","slug":"application_and_data"},{"id":2,"name":"Utilities","slug":"utilities"},{"id":3,"name":"DevOps","slug":"devops"},{"id":4,"name":"Business Tools","slug":"business_tools"}])
    stub_request(:get, "https://api.stackshare.io/v1/tools/layers?access_token=").to_return(body: layers_page_json)

    # Stubbing the /tools/lookup requests
    tools_1_json = %([{"id":2681,"name":"Punchtime for Trello","slug":"punchtime","popularity":1,"layer":{"id":1}},{"id":3262,"name":"Phoenix Framework","slug":"phoenix","popularity":3,"layer":{"id":1}}])
    stub_request(:get, "https://api.stackshare.io/v1/tools/lookup?access_token=&layer_id=1").to_return(body: tools_1_json)
    tools_2_json = %([{"id":2682,"name":"Punchtime2 for Trello","slug":"punchtime2","popularity":3,"layer":{"id":2}}])
    stub_request(:get, "https://api.stackshare.io/v1/tools/lookup?access_token=&layer_id=2").to_return(body: tools_2_json)
  end

  test "all_tags_from_page" do
    expected = [{"id"=>1, "name"=>"saas"}, {"id"=>2, "name"=>"cloud-computing"}, {"id"=>3, "name"=>"paas"}, {"id"=>4, "name"=>"big-data"}, {"id"=>5, "name"=>"ventures-for-good"}, {"id"=>6, "name"=>"consumer-lending"}, {"id"=>7, "name"=>"finance-technology"}, {"id"=>8, "name"=>"social-media"}]
    assert_equal expected, StackShareService.new.all_tags_from_page(1)
  end

  test "sync_all_tags!" do
    StackShareService.new.sync_all_tags!

    expected = ["saas", "cloud-computing", "paas", "big-data", "ventures-for-good", "consumer-lending", "finance-technology", "social-media"]
    assert_equal expected, Tag.order(:api_id).pluck(:name)
  end

  test "sync_all_layers!" do
    StackShareService.new.sync_all_layers!
    expected = ["application_and_data", "utilities", "devops", "business_tools"]
    assert_equal expected, Layer.order(:api_id).pluck(:slug)
  end

  test "sync_all_tools!" do
    StackShareService.new.sync_all_tools!
    expected = ["punchtime", "punchtime2", "phoenix"]
    assert_equal expected, Tool.order(:api_id).pluck(:slug)
    expected = ["application", "utilities", "application"]
    assert_equal expected, Tool.order(:api_id).map{|t|t.layer.slug}
  end

  test "object_from_api_id" do
    sss = StackShareService.new
    assert_equal 'cloud', sss.send(:object_from_api_id, Tag, 2).name
    assert_equal 'new_thing', sss.send(:object_from_api_id, Tag, 9).name

    assert_equal 'cloud', StackShareService.new.send(:object_from_api_id, Tag, 2, Tag.all).name
  end

end
