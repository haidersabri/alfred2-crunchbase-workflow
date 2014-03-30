# require "./bundle/bundler/setup"
require 'open-uri'
require 'nokogiri'
require 'alfred'
require 'uri'

class CrunchBaseCrawler

  def search(query)
    domain = "http://www.crunchbase.com"
    url = "#{domain}/search?query=#{query}"
    source = open(url).read
    doc = Nokogiri::HTML(source)
    results = doc.css(".search_result").map do |r|
      images = r.children.css("img")
      image_url = r.children.css("img").first["src"] if images.count > 0
      search_result_name = r.css(".search_result_name")
      url, company = search_result_name.css("a").first.values
      search_result_type = r.css(".search_result_type")
      type = search_result_type.inner_html.split.join(' ') if !search_result_type.nil?
      search_result_preview = r.css(".search_result_preview")
      preview = search_result_preview.children[1].inner_html if !search_result_preview.nil? && search_result_preview.children.count > 1
      { company: company, url: "#{domain}#{url}", type: type, preview: preview, image_url: image_url }
    end
    results
  end
end

def generate_feedback(alfred, arguments)
  query = arguments[0]
  cbAlfred = CrunchBaseCrawler.new
  results = cbAlfred.search(query)
  results.each do |item|
    alfred.feedback.add_item(
      :subtitle => item[:preview] ,
      :title    => item[:company],
      :uid      => item[:url], 
      :arg      => URI.escape(item[:url])
      )
  end
  
  puts alfred.feedback.to_xml(arguments)
end



Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  generate_feedback(alfred, ARGV)
end