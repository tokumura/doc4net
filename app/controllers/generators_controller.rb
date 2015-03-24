class GeneratorsController < ApplicationController
  def index
  end

  Member = Struct.new(:classname, :fields, :methods)

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

    class_list = Array.new
    is_first = true

    doc.xpath("//member").each do |m|

      attr_name = m.attribute("name").to_s

      if attr_name.include?("T:")
        if is_first
          is_first = false
        elsif is_target_member?(attr_name)
          @member.fields = @fields
          @member.methods = @methods
          class_list << @member
        end

        @member = Member.new(attr_name.gsub(/T:/, ""), nil, nil)
        @fields = Array.new
        @methods = Array.new

      elsif attr_name.include?("F:")
        @fields << m

      elsif attr_name.include?("M:")
        @methods << m
      end
    end
    class_list << @member

    @output = puts_class_list(class_list)
  end





  def puts_class_list class_list
    output = ""
    puts "#########"
    puts class_list.size
    class_list.each do |c|
      puts c.classname
      output = output + c.classname + "\r\n"
      if c.fields && c.fields.size > 0
        c.fields.each do |f|
          puts "  " + f.attribute("name").to_s
          output = output + "　　" + f.attribute("name").to_s + "\r\n"
        end
      end
      if c.methods && c.methods.size > 0
        c.methods.each do |method|
          puts "  " + method.attribute("name").to_s
          output = output + "　　" + method.attribute("name").to_s + "\r\n"
        end
      end
    end
    puts "#########"
    output
  end
end
