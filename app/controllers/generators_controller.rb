class GeneratorsController < ApplicationController
  def index
  end

  Service = Struct.new(:name, :summary, :methods)  #methods is array => Method 
  Method = Struct.new(:name, :summary, :returns, :params)  #params is array => String(name::japanese)
  
  def execute
    xml = params[:xml].read
    doc = Nokogiri::XML(xml)

    @service_list = Array.new
    all_method_list = Array.new

    doc.xpath('//member[starts-with(@name, "T:SharedLibrary.Service.")]').each do |tm|
      methods = Array.new
      service_name = tm.attribute("name").to_s.gsub(/T:/, "")
      service_summary = tm.xpath('./summary').text.strip
      puts service_summary

      doc.xpath("//member[starts-with(@name, \"M:#{service_name}\")]").each do |mm|
        method_name = get_method_name(mm)
        method_summary = mm.xpath('./summary').text.strip
        method_returns = get_method_returns(mm)
        method_params = get_method_params(mm)
        methods << Method.new(method_name, method_summary, method_returns, method_params)
      end

      @service_list << Service.new(service_name, service_summary, methods)
    end
  end

  def get_method_returns mm
    method_returns = "void"
    mm.xpath('./returns').each do |r|
      method_returns = r.text.strip
      break
    end
    method_returns
  end

  def get_method_name mm
    name = mm.attribute("name").to_s.gsub(/M:/, "")
    last_idx = name.split("(")[0].split(".").size - 1
    method_name = name.split("(")[0].split(".")[last_idx] + "()"
  end

  def get_method_params mm
    #params_type = name.split("(")[1].to_s.gsub(/\)/, "").split(",")
    method_params = Array.new
    mm.xpath('.//param').each do |p|
      method_params << p.attribute("name").to_s + "::" + p.text.strip
    end
    method_params
  end

end
