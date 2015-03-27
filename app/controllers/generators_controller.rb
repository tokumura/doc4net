class GeneratorsController < ApplicationController
  def index
    @appname = params[:appname]
  end

  Service = Struct.new(:name, :summary, :methods)  #methods is array => Method 
  Method = Struct.new(:name, :summary, :returns, :params)  #params is array => String(name::japanese)
  Param = Struct.new(:type, :name, :summary)
  
  # APIリファレンス生成
  #
  def execute
    @service_list = Array.new
    all_method_list = Array.new
    @appname = params[:appname]
    xml = params[:xml]

    if xml
      doc = Nokogiri::XML(xml.read)
      doc.xpath('//member[starts-with(@name, "T:SharedLibrary.Service.")]').each do |tm|
        methods = Array.new
        service_name = tm.attribute("name").to_s.gsub(/T:/, "")
        service_summary = tm.xpath('./summary').text.strip

        doc.xpath("//member[starts-with(@name, \"M:#{service_name}\")]").each do |mm|
          summary_array = get_method_params_summary(mm)
          type_array = get_params_type_array(mm)
          method_params = integrate_method_params(summary_array, type_array)
          method_name = get_method_name(mm, method_params)
          method_summary = mm.xpath('./summary').text.strip
          method_returns = get_method_returns(mm)
          methods << Method.new(method_name, method_summary, method_returns, method_params)
        end
        @service_list << Service.new(service_name, service_summary, methods)
      end
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

  def get_method_name mm, method_params
    name = mm.attribute("name").to_s.gsub(/M:/, "")
    last_idx = name.split("(")[0].split(".").size - 1
    method_name = name.split("(")[0].split(".")[last_idx]

    param_array = Array.new
    method_params.each do |p|
      param_array << p.split("::")[0].to_s + " " + p.split("::")[1].to_s
    end
    method_name = method_name + "(" + param_array.join(", ") + ")"
  end

  def get_method_params_summary mm
    #params_type = name.split("(")[1].to_s.gsub(/\)/, "").split(",")
    method_params = Array.new
    mm.xpath('.//param').each do |p|
      method_params << p.attribute("name").to_s + "::" + p.text.strip
    end
    method_params
  end

  def get_params_type_array mm
    params_array = Array.new
    method_name = mm.attribute("name").to_s.gsub(/M:/, "")
    if method_name.split("(").size > 0
      method_params = method_name.split("(")[1].to_s.gsub(/\)/, "").split(",")
    end

    method_params.each do |p|
      last_idx = p.split(".").size - 1
      type_name = p.split(".")[last_idx]
      if type_name.include?("}")
        params_array << "List<#{type_name.gsub(/}/, '')}>"
      else
        type_downcase = ["String", "Int32", "Boolean"]
        type_name.downcase! if type_downcase.include?(type_name)
        type_name = "out " + type_name.gsub(/@/, "") if type_name.include?("@")
        type_name = type_name.gsub(/int32/, "int")
        type_name = type_name.gsub(/boolean/, "bool")
        type_name = type_name.gsub(/Byte\[\]/, "byte[]")
        params_array << type_name
      end
    end

    params_array
  end

  def integrate_method_params summary_array, type_array
    params_array = Array.new
    summary_array.each_with_index do |summary, i|
      params_array << type_array[i].to_s + "::" + summary
    end
    params_array
  end


end
