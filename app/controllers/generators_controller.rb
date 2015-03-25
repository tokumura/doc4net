class GeneratorsController < ApplicationController
  def index
  end

  Member = Struct.new(:class, :methods)

  def is_target_member? attr_name
    #return true if attr_name.include?("SharedLibrary.Model")
    return true if attr_name.include?("SharedLibrary.Service")
    #return true if attr_name.include?("SharedLibrary.DTO")
    #return true if attr_name.include?("SharedLibrary.Util")
    false
  end
  
  def execute
    xml = params[:xml].read
    doc = Nokogiri::XML(xml)

    @class_list = Array.new
    all_method_list = Array.new

    doc.xpath('//member[starts-with(@name, "T:SharedLibrary.Service.")]').each do |tm|
      methods = Array.new
      class_name = tm.attribute("name").to_s.gsub(/T:/, "")
      doc.xpath("//member[starts-with(@name, \"M:#{class_name}\")]").each do |mm|
        methods << mm
      end
      @class_list << Member.new(tm, methods)
    end
  end
end
