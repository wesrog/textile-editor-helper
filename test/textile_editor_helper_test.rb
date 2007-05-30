require File.dirname(__FILE__) + '/abstract_unit'
require File.dirname(__FILE__) + '/../lib/textile_editor_helper'
require 'ostruct'

class TextileEditorHelperTest < Test::Unit::TestCase
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  include TextileEditorHelper
    
  def setup
    @controller = Class.new do
      attr_reader :url_for_options
      def url_for(options, *parameters_for_method_reference)
        @url_for_options = options
        "http://www.example.com"
      end
      
      def request;  @request  ||= ActionController::TestRequest.new;  end
      def response; @response ||= ActionController::TestResponse.new; end
    end
    @controller = @controller.new    
    @article = OpenStruct.new(:body => nil)
  end
  
  # support methods
  def create_simple_editor(object, field, options={})
    output = textile_editor(object, field, options.merge(:simple => true))
    assert_equal  text_area(object, field, options), output
  end  

  def create_extended_editor(object, field, options={})
    output = textile_editor(object, field, options)
    assert_equal  text_area(object, field, options), output
  end  
  
  def pre_initialize_output
    %{<link href="/stylesheets/textile-editor.css" media="screen" rel="Stylesheet" type="text/css" />
      <script src="/javascripts/textile-editor.js" type="text/javascript"></script>
      <script type="text/javascript">
      Event.observe(window, 'load', function() \{}
  end
  
  def post_initialize_output
    %{\});
      </script>
    }
  end
  
  def expected_initialize_output(editors, button_data=nil)
    expected = [pre_initialize_output]
    expected << button_data unless button_data.nil?
    expected << editors.map do |editor|
      "edToolbar('%s', '%s');" % editor
    end
    expected << post_initialize_output
    expected.join("\n").split("\n").map { |e| e.lstrip }.join("\n").chomp
  end
  
  # tests
  def test_textile_editor
    assert_nil @textile_editor_ids
    create_extended_editor('article', 'body')
    assert_equal [['article_body', 'extended']], @textile_editor_ids
  end
  
  def test_textile_editor_simple_mode
    assert_nil @textile_editor_ids
    create_simple_editor('article', 'body')
    assert_equal [['article_body', 'simple']], @textile_editor_ids
  end
  
  def test_textile_editor_with_custom_id
    assert_nil @textile_editor_ids
    create_extended_editor('article', 'body', :id => 'my_custom_id')
    assert_equal [['my_custom_id', 'extended']], @textile_editor_ids
  end  
  
  def test_textile_editor_simple_mode_with_custom_id
    assert_nil @textile_editor_ids
    create_simple_editor('article', 'body', :id => 'my_custom_id')
    assert_equal [['my_custom_id', 'simple']], @textile_editor_ids
  end
  
  def test_textile_editor_initialize
    create_extended_editor('article', 'body')
    output = textile_editor_initialize()
    assert_equal expected_initialize_output([
      ['article_body', 'extended']
    ]), output
    
    create_simple_editor('article', 'body_excerpt')
    output = textile_editor_initialize()
    assert_equal expected_initialize_output([
      ['article_body', 'extended'],
      ['article_body_excerpt', 'simple']
    ]), output
  end
  
  def test_textile_editor_inititalize_with_arbitrary_ids
    output = textile_editor_initialize(:story_comment, :story_body)
    assert_equal expected_initialize_output([
      ['story_comment', 'extended'],
      ['story_body', 'extended']
    ]), output
  end

  def test_textile_editor_initialize_with_custom_buttons
    button_data = ["theButtons.push(new edButtonCustom('test_button', 'Hello', function() { alert(\"Hello!\"); return false; }, \"Hello world\", ''));"]
    actual = textile_editor_button('Hello', 
      :id => 'test_button',
      :onclick => 'alert("Hello!")', 
      :title => 'Hello world'
    )    

    create_extended_editor('article', 'body')
    output = textile_editor_initialize()
    assert_equal expected_initialize_output([
      ['article_body', 'extended']
    ], button_data.join("\n")), output
  end

  def test_textile_extract_dom_ids_works_with_arrayed_hash
    hash_with_array = { :recipe => [ :instructions, :introduction ] }
    assert_equal [ 'recipe_instructions', 'recipe_introduction' ], textile_extract_dom_ids(hash_with_array)
  end

  def test_textile_extract_dom_ids_works_with_hash
    hash_with_symbol = { :story  => :title }
    assert_equal [ 'story_title' ], textile_extract_dom_ids(hash_with_symbol)
  end

  def test_textile_extract_dom_ids_works_with_ids
    straight_id = 'article_page'
    assert_equal [ 'article_page' ], textile_extract_dom_ids(straight_id)
  end

  def test_textile_extract_dom_ids_works_with_mixed_params
    paramd  = %w(article_page)
    paramd += [{ 
      :recipe => [ :instructions, :introduction ], 
      :story  => :title 
    }]
    assert_equal %w(article_page recipe_instructions recipe_introduction story_title).sort, 
      textile_extract_dom_ids(*paramd).sort { |a,b| a.to_s <=> b.to_s }
  end
  
  def test_textile_editor_button
    expected = ["theButtons.push(new edButtonCustom('test_button', 'Hello', function() { alert(\"Hello!\"); return false; }, \"Hello world\", ''));"]
    actual = textile_editor_button('Hello', 
      :id => 'test_button',
      :onclick => 'alert("Hello!")', 
      :title => 'Hello world'
    )
    
    assert_equal expected, actual
  end  
  
  def test_textile_editor_button_simple
    expected = ["theButtons.push(new edButtonCustom('test_button', 'Hello', function() { alert(\"Hello!\"); return false; }, \"Hello world\", 's'));"]
    actual = textile_editor_button('Hello', 
      :id => 'test_button',
      :onclick => 'alert("Hello!")', 
      :title => 'Hello world',
      :simple => true
    )
    
    assert_equal expected, actual
  end
end